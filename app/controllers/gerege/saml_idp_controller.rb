require_relative "../../../lib/gerege/saml_config"

module Gerege
  class SamlIdpController < ApplicationController
    layout false
    include SamlIdp::Controller

    before_action :store_authn_request, only: %i[sso_request], unless: :user_signed_in?
    before_action :validate_session
    before_action :load_config, only: %i[sso_request slo_request initiate_slo metadata]
    before_action :validate_saml_request, only: %i[sso_request slo_request], if: :sp_initiated_request?

    def sso_request
      saml_response
      render :sso_response
    end

    def slo_request
      return redirect_to Gerege.config.relay_state_url, allow_other_host: true unless sp_initiated_request?

      saml_slo_response = encode_logout_response(
        current_saml_user,
        @saml_config.append_request_config(saml_request).merge!(
          public_cert: current_sp_config.certificate,
          private_key: current_sp_config.private_key,
          pv_key_password: current_sp_config.pv_key_password
        )
      )

      # TODO: move this part to gem
      # If SLO request doesn't contain the SLO endpoint then use SP config default SLO url
      @sp_slo_endpoint = saml_request&.logout_url || current_sp_config.single_logout_services&.values&.first
      @sp_slo_binding = current_sp_config.single_logout_services&.keys&.first == "HTTP-Redirect" ? :redirect : :post
      saml_slo_response = Zlib::Deflate.deflate(saml_slo_response, 9)[2..-5] if @sp_slo_binding == :redirect
      @saml_slo_response = Base64.strict_encode64(saml_slo_response)
      @sp_slo_url = generate_url(host: @sp_slo_endpoint, SAMLResponse: @saml_slo_response, RelayState: Gerege.config.relay_state_url)
      render :slo_response
    end

    def initiate_slo
      # TODO: move it out to "saml_idp" gem
      slo_endpoint = current_sp_config.single_logout_services
      binding = slo_endpoint&.keys&.first == "HTTP-Redirect" ? :get : :post
      slo_location = slo_endpoint&.values&.first

      logout_request = SamlIdp::LogoutRequestBuilder.new(
        SecureRandom.uuid,
        Gerege.config.base_url,
        slo_location,
        current_sp_config.name_id_value,
        OpenSSL::Digest::SHA256 # TODO: Update this to use the SP's digest method
      ).signed

      @slo_request_params = {
        name: sp_config.name,
        location: slo_location,
        params: {
          SAMLRequest: binding == :get ? Base64.encode64(logout_request) : logout_request,
          RelayState: Gerege.config.relay_state_url
        },
        method: binding
      }
      render :slo_request
    end

    def metadata
      render xml: @saml_config.idp_metadata
    end

    def attribute
      render xml: current_sp_config.saml_attributes_as_hash.to_xml(root: "Attributes")
    end

    private

    def saml_response
      @saml_response = encode_authn_response(
        current_saml_user,
        @saml_config.append_request_config(saml_request).merge!(
          public_cert: current_sp_config.certificate,
          private_key: current_sp_config.private_key,
          pv_key_password: current_sp_config.pv_key_password
        )
      )
    end

    def saml_request
      # GEM will decode SP initiated request which is mean @saml_request set by gem
      sp_initiated_request? ? @saml_request : @saml_config.saml_request
    end

    def sp_initiated_request?
      params[:SAMLRequest].present?
    end

    def current_sp_config
      @current_sp_config ||= Gerege.config.saml_config_finder.call
    end

    def current_saml_user
      @current_saml_user ||= Gerege.config.saml_user_finder.call
    end

    def store_authn_request
      saml_authn_request = if request.post?
        saml_post_req = { SAMLRequest: params[:SAMLRequest], RelayState: params[:RelayState] }
        "#{request.fullpath}?#{saml_post_req.to_query}"
      else
        request.fullpath
      end

      session[:sp_config_id] = current_sp_config.id
      session[:saml_auth_request] = saml_authn_request

      redirect_to Gerege.config.sign_in_url, allow_other_host: true
    end

    def user_signed_in?
      current_saml_user.present?
    end

    def load_config
      @saml_config = Gerege::SamlConfig.new(current_sp_config, current_saml_user)
      @saml_config.configure_saml_idp
    end

    def validate_session
      Gerege.config.session_validation_hook.call(session) if Gerege.config.session_validation_hook.present?
    end

    def generate_url(host:, **params)
      "#{host}?#{params.to_query}"
    end
  end
end

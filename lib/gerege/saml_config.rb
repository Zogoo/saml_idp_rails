require "saml_idp"

module Gerege
  class SamlConfig
    include Gerege::Engine.routes.url_helpers

    attr_accessor :config

    def initialize(sp_config, saml_user)
      @config = {}
      @config[:base_url] = Gerege.config.base_url
      @config[:saml_config] = sp_config
      @config[:saml_user] = saml_user
    end

    def configure_saml_idp
      ::SamlIdp.configure do |config|
        config.x509_certificate = saml_config.certificate
        config.secret_key = saml_config.private_key
        config.password = saml_config.pv_key_password
        config.algorithm = :sha256
        config.organization_name = base_url
        config.organization_url = base_url
        # URL configuration
        config.base_saml_location = base_url # TODO: Read from gem configuration
        config.single_logout_service_post_location = slo_post_endpoint
        config.single_logout_service_redirect_location = slo_redirect_endpoint
        config.attribute_service_location = attribute_endpoint
        config.single_service_post_location = sso_post_endpoint
        config.single_service_redirect_location = sso_redirect_endpoint
        # Name ID format
        config.name_id.formats = name_id_format
        config.attributes = saml_attributes_as_hash
        config.service_provider.metadata_persister = metadata_persister
        config.service_provider.persisted_metadata_getter = persisted_matadata
        config.service_provider.finder = service_providers
        config.logger = Rails.logger
      end
    end

    def append_request_config(saml_request)
      config = {}
      if saml_config.encryption_certificate.present?
        config = {
          encryption: {
            cert: saml_config.encryption_certificate,
            block_encryption: "aes256-cbc",
            key_transport: "rsa-oaep-mgf1p"
          }
        }
      end

      config[:signed_assertion] = saml_config.sign_assertions
      config[:signed_message] = true

      # SP initiated SAML
      if saml_request.present? && !saml_request.try(:idp_initiated?)
        config[:acs_url] = saml_request.request["AssertionConsumerServiceURL"] if saml_request.authn_request?
        return config
      end

      config.merge!(audience_uri: saml_config.entity_id)
    end

    def idp_metadata
      SamlIdp.metadata.signed
    end

    def saml_request
      @saml_request ||= Struct.new(
        :request_id,
        :issue_url,
        :acs_url
      ) do
        def authn_request?
          true
        end

        def idp_initiated?
          true
        end

        def issuer
          url = URI(issue_url)
          url.query = nil
          url.to_s
        end
      end.new(nil, base_url, default_acs_config[:location])
    end

    def name_id_value(attribute_name = nil)
      attr = attribute_name.presence || saml_user.name_id_attribute
      val =  saml_user.public_send(attr) if saml_user.respond_to?(attr)
      raise("Gerege: Name ID attribute #{attr} is not set") if val.blank?
      val
    end

    private

    def service_providers
      lambda { |_issuer_or_entity_id|
        {
          response_hosts: saml_config.assertion_consumer_services.map do |acs|
            url = acs["location"] || acs[:location]
            URI(url).host
          end,
          acs_url: default_acs_config[:location],
          cert: (saml_config.signing_certificate.present? ? saml_config.signing_certificate : nil),
          fingerprint: (saml_config.signing_certificate.present? ? SamlIdp::Fingerprint.certificate_digest(saml_config.signing_certificate, :sha256) : nil),
          assertion_consumer_logout_service_url: saml_config.single_logout_services.values.first,
          sign_authn_request: saml_config.sign_authn_request
        }
      }
    end

    def persisted_matadata
      lambda { |_identifier, _|
        # TODO: eliminate raw metadata usage
        SamlIdp::IncomingMetadata.new(saml_config.raw_metadata)
      }
    end

    # We don't need support it because, scary XML can be there
    # TODO: Remove this method from GEM
    def metadata_persister
      lambda { |_identifier, _service_provider|
      }
    end

    def default_name_idp_format
      {
        "1.1" => {
          email_address: lambda { |_principal|
            name_id_value
          }
        }
      }
    end

    def name_id_format
      first_name_format = saml_config.name_id_formats.first.to_s
      first_name_format = "unspecified" if first_name_format.blank?
      {
        name_id_format_version(first_name_format).to_s => {
          # TODO: Remove lambdas from GEM
          first_name_format => lambda { |_principal|
            name_id_value
          }
        }
      }
    end

    def name_id_format_version(parsed_format)
      return "1.1" if %w[email_address unspecified].include?(parsed_format.underscore)

      "2.0"
    end

    def default_acs_config
      (saml_config.assertion_consumer_services.first || {}).with_indifferent_access
    end

    def saml_attributes_as_hash
      config_attribute = {}
      saml_config.saml_attributes.each do |attribute|
        # TODO: Resolve this issue on GEM side
        attribute["name_format"] = attribute["nameFormat"] if attribute["nameFormat"].present?

        config_attribute[attribute["friendlyName"]] = attribute.except("friendlyName")
        # TODO: Remove lambdas from GEM
        config_attribute[attribute["friendlyName"]]["getter"] = lambda { |_principal|
          saml_attribute_getters(attribute["getter"])
        }
      end
      config_attribute
    end

    def saml_attribute_getters(config_value)
      attribute_value = user_attribute(config_value)
      attribute_type = attribute_value.class.to_s
      # Fixed string value
      return config_value.to_s if attribute_value.blank?

      case attribute_type
      when "Array"
        attribute_value.map(&:to_s)
      when "Hash"
        attribute_value.to_json
      when "Integer"
        attribute_value.to_s
      when "String"
        attribute_value
      else
        ""
      end
    end

    def user_attribute(key)
      saml_user.respond_to?(key) ? saml_user.public_send(key) : saml_user[key]
    end

    def metadata_endpoint
      @config[:metadata_url] || metadata_url(uuid: saml_config.uuid, host: base_url)
    end

    def slo_post_endpoint
      @config[:slo_post_url] || slo_post_url(uuid: saml_config.uuid, host: base_url)
    end

    # Form converts REDIRECT to POST
    def slo_redirect_endpoint
      @config[:metadata_url] || slo_redirect_url(uuid: saml_config.uuid, host: base_url)
    end

    def attribute_endpoint
      @config[:attribute_url] || attribute_url(uuid: saml_config.uuid, host: base_url)
    end

    def sso_post_endpoint
      @config[:sso_post_url] || sso_post_url(uuid: saml_config.uuid, host: base_url)
    end

    # Form converts REDIRECT to POST
    def sso_redirect_endpoint
      @config[:sso_redirect_url] || sso_redirect_url(uuid: saml_config.uuid, host: base_url)
    end

    def saml_user
      @config[:saml_user] || raise("Gerege: saml_user is not set")
    end

    def saml_config
      @config[:saml_config] || raise("Gerege: saml_config is not set")
    end

    def base_url
      @config[:base_url] || raise("Gerege: base_url is not set")
    end
  end
end

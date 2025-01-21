require "test_helper"
require_relative "../../../test/helpers/saml_sp_helper.rb"

module Gerege
  class SamlIdpControllerTest < ActionDispatch::IntegrationTest
    include SamlSpHelper
    include Engine.routes.url_helpers

    User = Struct.new(:name_id_attribute, :email, keyword_init: true)

    setup do
      @sp_config = gerege_saml_sp_configs(:one)
      @sp_config.certificate = File.read("test/fixtures/saml/keys/public_key.pem")
      @sp_config.private_key = File.read("test/fixtures/saml/keys/private_key.pem")
      @sp_config.pv_key_password = "password"
      @sp_config.signing_certificate = File.read("test/fixtures/saml/keys/public_key.pem")
      @sp_config.encryption_certificate = nil # Skip encryption for now

      @user = User.new(
        name_id_attribute: "email",
        email: "user@example.com"
      )
      @saml_request = "sample_saml_request"
      @relay_state = "sample_relay_state"

      Gerege.configure do |config|
        config.base_url = "https://idp.example.com"
        config.sign_in_url = "https://idp.example.com/sign_in"
        config.relay_state_url = "https://idp.example.com/home_page"
        config.saml_config_finder = -> { @sp_config }
        config.saml_user_finder = -> { @user }
        config.session_validation_hook = ->(session) { true } # Skip validation
      end
    end

    test "should get metadata" do
      get metadata_path(uuid: @sp_config.uuid)
      assert_response :success
      assert_match /<EntityDescriptor/, response.body
    end

    test "should handle SSO request and respond with SAML response" do
      client_setting = sp_settings(@sp_config)
      authn_params = create_authn_request(client_setting)
      get sso_redirect_path(uuid: @sp_config.uuid), params: authn_params
      assert_response :success
      assert_match /<input type="hidden" name="SAMLResponse" id="SAMLResponse" value="[^"]+/, response.body
      assert_template :sso_response
    end

    test "should store authn request for unsigned user" do
      Gerege.config.saml_user_finder = -> { nil }
      client_setting = sp_settings(@sp_config)
      authn_params = create_authn_request(client_setting)
      get sso_redirect_path(uuid: @sp_config.uuid), params: authn_params
      assert_response :redirect
      assert_redirected_to Gerege.config.sign_in_url
      assert_equal session[:sp_config_id], @sp_config.id
      assert_not_nil session[:saml_auth_request]
    end

    test "should handle SLO request" do
      client_setting = sp_settings(@sp_config)
      slo_params = create_slo_request(client_setting)
      get slo_redirect_path(uuid: @sp_config.uuid), params: slo_params
      assert_response :success
    end

    # test 'should initiate SLO' do
    #   post initiate_slo_path(uuid: @sp_config.uuid)
    #   assert_response :success
    #   assert_template :slo_request
    #   assert_not_nil assigns(:slo_request_params)
    # end

    # test 'should encode SAML response' do
    #   Gerege::SamlIdpController.any_instance.stubs(:user_signed_in?).returns(true)
    #   Gerege::SamlIdpController.any_instance.expects(:encode_authn_response)
    #     .with(@saml_user, anything).returns('mocked_response')

    #   post sso_post_path(uuid: @sp_config.uuid, SAMLRequest: generate_saml_request)
    #   assert_response :success
    #   assert assigns(:saml_response)
    # end

    private

    def generate_saml_request
      Base64.strict_encode64(SamlIdp::RequestBuilder.new(SecureRandom.uuid).build)
    end
  end
end

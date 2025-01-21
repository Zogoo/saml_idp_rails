require "test_helper"
require_relative "../../../lib/gerege/saml_config"


module Gerege
  class SamlConfigTest < ActiveSupport::TestCase
    User =  Struct.new(:name_id_attribute, :email, keyword_init: true)

    setup do
      @sp_config = gerege_saml_sp_configs(:one)
      @user = User.new(
        name_id_attribute: "email",
        email: "user@example.com"
      )
      @sp_config.certificate = File.read("test/fixtures/saml/keys/public_key_enc.pem")
      @sp_config.private_key = File.read("test/fixtures/saml/keys/private_key_enc.pem")
      @sp_config.pv_key_password = "password"
      @sp_config.signing_certificate = File.read("test/fixtures/saml/keys/public_key.pem")
      @sp_config.encryption_certificate = File.read("test/fixtures/saml/keys/public_key.pem")

      Gerege.configure do |config|
        config.saml_config_finder = ->() { @sp_config }
        config.saml_user_finder = ->() { @user }
        config.base_url = "https://idp.example.com"
        config.sign_in_url = "https://idp.example.com/sign_in"
        config.relay_state_url = "https://idp.example.com/home_page"
        config.session_validation_hook = ->(session) { session }
      end
      @saml_config = Gerege::SamlConfig.new(@sp_config, @user)
    end

    test "should initialize with sp_config and saml_user" do
      assert_equal @sp_config, @saml_config.config[:saml_config]
      assert_equal @user.email, @saml_config.config[:saml_user].email
    end

    test "should configure saml_idp" do
      @saml_config.configure_saml_idp
      config = SamlIdp.config

      assert_equal @sp_config.certificate, config.x509_certificate
      assert_equal @sp_config.private_key, config.secret_key
      assert_equal @sp_config.pv_key_password, config.password
      assert_equal :sha256, config.algorithm
      assert_equal Gerege.config.base_url, config.organization_name
      assert_equal Gerege.config.base_url, config.organization_url
    end

    test "should apply request config" do
      saml_request = @saml_config.saml_request
      config = @saml_config.append_request_config(saml_request)

      assert_equal @sp_config.entity_id, config[:audience_uri]
      assert config[:signed_message]
    end

    test "should return saml_request" do
      saml_request = @saml_config.saml_request
      assert saml_request.authn_request?
    end

    test "should return service_providers" do
      service_providers = @saml_config.send(:service_providers).call(nil)
      assert_not_nil service_providers[:response_hosts]
      assert_not_nil service_providers[:acs_url]
    end

    test "should return persisted_metadata" do
      persisted_metadata = @saml_config.send(:persisted_matadata).call(nil, nil)
      assert_not_nil persisted_metadata
    end

    test "should return default_name_idp_format" do
      name_idp_format = @saml_config.send(:default_name_idp_format)
      assert_not_nil name_idp_format["1.1"][:email_address]
    end

    test "should return name_id_format" do
      name_id_format = @saml_config.send(:name_id_format)
      assert_not_nil name_id_format["1.1"]["email_address"]
    end

    test "should return name_id_value" do
      name_id_value = @saml_config.send(:name_id_value)
      assert_equal "user@example.com", name_id_value
    end

    test "should convert saml attributes to hash" do
      attributes_hash = @saml_config.send(:saml_attributes_as_hash)

      assert_not_nil attributes_hash["Email address"] # Friendly name
      assert_equal "urn:oasis:names:tc:SAML:2.0:attrname-format:basic", attributes_hash["Email address"]["nameFormat"] # Saml IdP gem config
    end
  end
end

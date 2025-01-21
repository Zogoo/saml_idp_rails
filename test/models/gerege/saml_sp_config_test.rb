require "test_helper"

module Gerege
  class SamlSpConfigTest < ActiveSupport::TestCase
    setup do
      @saml_sp_config = gerege_saml_sp_configs(:one)
    end

    test "should load raw metadata and assign attributes" do
      @saml_sp_config.raw_metadata = File.read("test/fixtures/saml/sp_metadata.xml")
      @saml_sp_config.parsed_metadata

      assert_not_nil @saml_sp_config.name_id_formats
      assert_not_nil @saml_sp_config.assertion_consumer_services
      assert_not_nil @saml_sp_config.signing_certificate
      assert_not_nil @saml_sp_config.encryption_certificate
    end

    test "should handle unspecified certificate" do
      @saml_sp_config.raw_metadata = File.read("test/fixtures/saml/no_key_usage_metadata.xml")
      @saml_sp_config.parsed_metadata

      assert_match /^-----BEGIN CERTIFICATE-----/, @saml_sp_config.signing_certificate
      assert_match /-----END CERTIFICATE-----$/, @saml_sp_config.signing_certificate
    end

    test "should encode certificates" do
      @saml_sp_config.signing_certificate = "sample_signing_certificate"
      @saml_sp_config.encryption_certificate = "sample_encryption_certificate"
      @saml_sp_config.send(:encoded_certificates)

      assert_match /^-----BEGIN CERTIFICATE-----/, @saml_sp_config.signing_certificate
      assert_match /^-----BEGIN CERTIFICATE-----/, @saml_sp_config.encryption_certificate
    end

    test "should generate UUID before create" do
      saml_sp_config = Gerege::SamlSpConfig.new
      saml_sp_config.save
      assert_not_nil saml_sp_config.uuid
    end

    test "should format certificates with PEM" do
      cert = "sample_certificate"
      formatted_cert = @saml_sp_config.send(:format_with_pem, cert)

      assert_match /^-----BEGIN CERTIFICATE-----/, formatted_cert
      assert_match /-----END CERTIFICATE-----$/, formatted_cert
    end

    test "should check if certificate is PEM formatted" do
      cert = "-----BEGIN CERTIFICATE-----\nsample_certificate\n-----END CERTIFICATE-----"
      assert @saml_sp_config.send(:pem_formatted?, cert)
    end
  end
end

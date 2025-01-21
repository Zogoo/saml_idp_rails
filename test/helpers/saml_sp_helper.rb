require "ruby-saml"

module SamlSpHelper
  def create_authn_request(settings = nil)
    authn_request = OneLogin::RubySaml::Authrequest.new
    authn_request.create_params(settings).merge!(RelayState: "http://test-sp-one.com/home")
  end

  def create_slo_request(settings = nil)
    slo_request = OneLogin::RubySaml::Logoutrequest.new
    slo_request.create_params(settings).merge!(RelayState: "http://test-sp-one.com/home")
  end

  def sp_settings(saml_sp_config, idp_entity_id: "https://idp.example.com", sso_post_url: "https://idp.example.com/post", slo_post_url: "https://idp.example.com/slo")
    setting = OneLogin::RubySaml::Settings.new

    # No need to raise error
    setting.soft = true

    # SP settings
    setting.issuer                         = saml_sp_config.entity_id
    setting.assertion_consumer_service_url = saml_sp_config.assertion_consumer_services.first["location"]
    setting.assertion_consumer_logout_service_url = "http://test-sp-one.com/slo"
    setting.private_key = File.read("test/fixtures/saml/keys/private_key.pem")
    setting.certificate = File.read("test/fixtures/saml/keys/public_key.pem")

    # IdP setings
    setting.idp_entity_id                  = idp_entity_id
    setting.idp_sso_target_url             = sso_post_url
    setting.idp_slo_target_url             = slo_post_url
    setting.idp_cert                       = saml_sp_config.certificate
    setting.idp_cert_fingerprint           = SamlIdp::Fingerprint.certificate_digest(saml_sp_config.certificate, :sha256)
    setting.name_identifier_format         = saml_sp_config.name_id_formats.first

    enable_security(setting, authn_requests_signed: saml_sp_config.sign_authn_request)

    setting
  end

  def enable_security(setting, authn_requests_signed: false)
    setting.security[:authn_requests_signed] = authn_requests_signed
    setting.security[:embed_sign] = true
    setting.security[:logout_requests_signed] = true
    setting.security[:logout_responses_signed] = false
    setting.security[:metadata_signed] = false
    setting.security[:digest_method] = XMLSecurity::Document::SHA256
    setting.security[:signature_method] = XMLSecurity::Document::RSA_SHA256
  end
end

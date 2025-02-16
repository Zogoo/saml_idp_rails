SamlIdpRails::Engine.routes.draw do
  get ":uuid/metadata", to: "saml_idp#metadata", as: "metadata"
  post ":uuid/sso", to: "saml_idp#sso_request", as: "sso_post"
  get ":uuid/sso", to: "saml_idp#sso_request", as: "sso_redirect"
  post ":uuid/logout", to: "saml_idp#slo_request", as: "slo_post"
  get ":uuid/logout", to: "saml_idp#slo_request", as: "slo_redirect"
  post ":uuid/slo_request", to: "saml_idp#initiate_slo", as: "initiate_slo"
  get ":uuid/attribute", to: "saml_idp#attribute", as: "attribute"
end

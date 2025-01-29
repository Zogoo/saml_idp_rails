SamlIdpRails::Engine.routes.draw do
  get "saml_idp/:uuid/metadata", to: "saml_idp#metadata", as: "metadata"
  post "saml_idp/:uuid/sso", to: "saml_idp#sso_request", as: "sso_post"
  get "saml_idp/:uuid/sso", to: "saml_idp#sso_request", as: "sso_redirect"
  post "saml_idp/:uuid/logout", to: "saml_idp#slo_request", as: "slo_post"
  get "saml_idp/:uuid/logout", to: "saml_idp#slo_request", as: "slo_redirect"
  post "saml_idp/:uuid/slo_request", to: "saml_idp#initiate_slo", as: "initiate_slo"
  get "saml_idp/:uuid/attribute", to: "saml_idp#attribute", as: "attribute"
end

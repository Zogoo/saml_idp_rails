Rails.application.routes.draw do
  mount SamlIdpRails::Engine => "/saml_idp_rails"
end

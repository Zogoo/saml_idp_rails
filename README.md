# SamlIdpRails
A Ruby gem that implements SAML Identity Provider (IdP) functionality for Rails applications.

## Usage
This gem allows you to add SAML IdP capabilities to your Rails application.

## Installation

1. Add this line to your Rails application's Gemfile:

```ruby
gem "saml_idp_rails"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install saml_idp_rails
```

2. Generate the necessary migrations for Active Record:
```bash
bin/rails saml_idp_rails:install:migrations
```

3. Migrate the Service Provider settings to your database:
```bash
bin/rails db:migrate
```

4. Configure your IdP service:
Create a configuration file in your Rails initializers directory:

```rb
# config/initializers/saml_idp_config.rb

SamlIdpRails.configure do |config|
  # Base URL of your application
  config.base_url = "http://localhost:3000"
  
  # URL where users will be redirected to sign in
  config.sign_in_url = "/users/sign_in"
  
  # Default URL to redirect after successful authentication
  config.relay_state_url = "/home"
  
  # Hook to validate user session
  config.session_validation_hook = ->(session) { true }
  
  # Lambda to find SAML Service Provider configuration
  config.saml_config_finder = lambda do |_request|
    SamlIdpRails::SamlSpConfig.find_by(uuid: params.require(:uuid))
  end
  
  # Lambda to find and return user information for SAML response
  config.saml_user_finder = lambda do |_request|
    User = Struct.new(:name_id_attribute, :email, keyword_init: true)
    User.new(
      name_id_attribute: "email",
      email: "user@example.com"
    )
  end
end
```

5. Create a Service Provider (SP) configuration:
After running migrations, you'll find a migration file in your Rails app under:
`db/migrate/YYYYMMDDHHMMSS_create_saml_idp_rails_saml_sp_configs.saml_idp_rails.rb`

Example of creating an SP configuration:

```rb
SamlIdpRails::SamlSpConfig.create(
  # Basic SP Information
  name: "Test SP Config One",                # Unique identifier for the SP configuration
  display_name: "Test SP One",               # Human-readable name for the SP
  entity_id: "http://test-sp-one.com",      # Entity ID provided by the SP
  
  # Certificate and Key Configuration
  signing_certificate: "Your IdP public key",    # Base64 encoded IdP public key
  encryption_certificate: nil,                   # Optional: SP encryption certificate
  private_key: "Your IdP private key",          # IdP private key (keep secure)
  pv_key_password: nil,                         # Optional: Private key password if encrypted
  
  # SAML Settings
  sign_assertions: true,                    # Whether to sign SAML assertions
  sign_authn_request: false,                # Whether SP requires signed authentication requests
  certificate: "SP X509 certificate",       # SP's public certificate for signature validation
  relay_state: "sample_relay_state",        # Post-SSO redirect URL
  name_id_attribute: "email",               # Attribute to use as NameID
  raw_metadata: nil,                        # Optional: Raw SP metadata XML
  
  # SAML Format Settings
  name_id_formats: ["email_address"],       # Supported NameID formats
  
  # Service Endpoints
  assertion_consumer_services: [{
    "binding" => "HTTP-POST",
    "default" => "true",
    "location" => "http://test-sp-one.com/acs"
  }],
  single_logout_services: {
    "HTTP-Redirect" => "http://test-sp-one.com/slo"
  },
  
  # Contact Information
  contact_person: {
    "surname" => "Doe",
    "given_name" => "John",
    "email_address" => "john.doe@test-sp-one.com"
  },
  
  # SAML Attributes
  saml_attributes: [{
    "name" => "email",
    "getter" => "email",
    "nameFormat" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
    "name_format" => "urn:oasis:names:tc:SAML:2.0:attrname-format:basic",
    "friendlyName" => "Email address"
  }],
  
  # Public Identifier
  uuid: "8ad17d2a-f870-4796-8212-7487411b8578"  # Unique identifier for SP configuration
)
```

## Contributing
To contribute, fork the repository and create a pull request with your changes.

## License
This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

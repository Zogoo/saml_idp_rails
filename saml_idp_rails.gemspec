require_relative "lib/saml_idp_rails/version"

Gem::Specification.new do |spec|
  spec.name        = "saml_idp_rails"
  spec.version     = SamlIdpRails::VERSION
  spec.authors     = [ "zogoo" ]
  spec.email       = [ "ch.zogoo@gmail.com" ]
  spec.homepage    = "https://github.com/zogoo/saml_idp_rails"
  spec.summary     = "Idp controller for Rails"
  spec.description = "SamlIdpRails is open source Idp controller for Rails."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.1"
  spec.add_dependency "saml_idp"

  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "ruby-saml"
end

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

  # For GitHub Packages, set the allowed push host to GitHub's package registry
  spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/zogoo"
  spec.metadata["github_repo"] = "zogoo/saml_idp_rails"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/zogoo/saml_idp_rails"
  spec.metadata["changelog_uri"] = "https://github.com/Zogoo/saml_idp_rails/blob/master/CHANGELOG.md"

  spec.required_ruby_version = ">= 3.4.1"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.0.1"
  spec.add_dependency "saml_idp"

  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "debug"
  spec.add_development_dependency "ruby-saml"
end

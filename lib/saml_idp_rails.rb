require "saml_idp_rails/version"
require "saml_idp_rails/engine"
require "saml_idp_rails/config"

module SamlIdpRails
  class << self
    def configure(&block)
      @config = Config.new.configure(&block)
      @config.validate!
    end

    def config
      @config
    end
  end
end

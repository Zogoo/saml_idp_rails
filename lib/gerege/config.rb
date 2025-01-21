require "saml_idp"

module Gerege
  class Config
    ATTRIBUTES = %i[
      base_url
      sign_in_url
      relay_state_url
      session_validation_hook
      saml_config_finder
      saml_user_finder
    ].freeze

    attr_accessor *ATTRIBUTES

    def configure(&block)
      yield self if block_given?
      self
    end

    def validate!
      ATTRIBUTES.each do |attribute|
        raise("Gerege: #{attribute} is not set") if self.public_send(attribute).nil?
      end
    end
  end
end

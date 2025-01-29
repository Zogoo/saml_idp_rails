require "test_helper"
require "debug"

module SamlIdpRails
  class ConfigTest < ActiveSupport::TestCase
    setup do
      @config = SamlIdpRails::Config.new
    end

    test "should configure attributes" do
      @config.configure do |config|
        config.saml_config_finder = -> { "saml_config" }
        config.saml_user_finder = -> { "saml_user" }
        config.base_url = "http://example.com"
        config.sign_in_url = "http://example.com/sign_in"
        config.relay_state_url = "http://example.com/home_page"
        config.session_validation_hook = ->(session) { session }
      end

      assert_equal "saml_config", @config.saml_config_finder.call
      assert_equal "saml_user", @config.saml_user_finder.call
      assert_equal "http://example.com", @config.base_url
      assert_equal "http://example.com/sign_in", @config.sign_in_url
      assert_equal "http://example.com/home_page", @config.relay_state_url
      assert_nothing_raised { @config.validate! }
    end

    test "should raise error for missing attributes" do
      @config.configure do |config|
        config.saml_config_finder = -> { "saml_config" }
        config.saml_user_finder = -> { "saml_user" }
      end
      assert_raises(RuntimeError) { @config.validate! }
    end
  end
end

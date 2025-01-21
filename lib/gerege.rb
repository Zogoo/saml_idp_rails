require "gerege/version"
require "gerege/engine"
require "gerege/config"

module Gerege
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

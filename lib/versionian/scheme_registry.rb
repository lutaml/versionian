# frozen_string_literal: true

require "singleton"

module Versionian
  class SchemeRegistry
    include Singleton

    def initialize
      @schemes = {}
      @mutex = Mutex.new
    end

    def register(name, scheme)
      @mutex.synchronize do
        @schemes[name] = scheme
      end
    end

    def get(name)
      @schemes[name] || raise(Errors::InvalidSchemeError, "Unknown scheme: #{name}")
    end

    def registered
      @schemes.keys
    end

    def detect_from(version_string)
      @schemes.values.find do |scheme|
        scheme.valid?(version_string)
      end
    end
  end
end

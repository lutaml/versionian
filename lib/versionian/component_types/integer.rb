# frozen_string_literal: true

module Versionian
  module ComponentTypes
    class Integer < Base
      def self.parse(value, definition)
        return definition.default.to_i if value.nil? || value.empty?

        Kernel.Integer(value)
      rescue ArgumentError, TypeError => e
        raise Errors::ParseError, "Invalid integer '#{value}': #{e.message}"
      end

      def self.to_comparable(value, _definition)
        value
      end

      def self.format(value)
        value.to_s
      end
    end
  end
end

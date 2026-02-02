# frozen_string_literal: true

module Versionian
  module ComponentTypes
    class Float < Base
      def self.parse(value, definition)
        return definition.default.to_f if value.nil? || value.empty?

        ::Kernel.Float(value)
      rescue ArgumentError, TypeError => e
        raise Errors::ParseError, "Invalid float '#{value}': #{e.message}"
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

# frozen_string_literal: true

module Versionian
  module ComponentTypes
    class Hash < Base
      def self.parse(value, definition)
        return definition.default if value.nil? || value.empty?

        value.downcase # Normalize to lowercase
      end

      def self.to_comparable(value, _definition)
        [value.length, value] # Compare by length first, then lexicographically
      end

      def self.format(value)
        value
      end
    end
  end
end

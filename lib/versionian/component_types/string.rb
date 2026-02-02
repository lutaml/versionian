# frozen_string_literal: true

module Versionian
  module ComponentTypes
    class String < Base
      def self.parse(value, definition)
        return definition.default || "" if value.nil? || value.empty?

        value.to_s
      end

      def self.to_comparable(value, _definition)
        value
      end

      def self.format(value)
        value
      end
    end
  end
end

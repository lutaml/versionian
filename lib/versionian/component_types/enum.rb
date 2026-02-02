# frozen_string_literal: true

module Versionian
  module ComponentTypes
    class Enum < Base
      def self.parse(value, definition)
        return nil if value.nil? || value.empty?

        sym = value.to_sym

        if definition.values && !definition.values.empty? && !definition.values.include?(sym)
          raise Errors::ParseError,
                "Invalid enum value '#{value}' for #{definition.name}. Allowed: #{definition.values.join(", ")}"
        end

        sym
      end

      def self.to_comparable(value, definition)
        return ::Float::INFINITY if value.nil?

        # Use the definition's order array
        order = definition.order || []
        order.index(value) || (order.length + 1)
      end

      def self.format(value)
        value.nil? ? "" : value.to_s
      end
    end
  end
end

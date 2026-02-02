# frozen_string_literal: true

module Versionian
  module ComponentTypes
    class Postfix < Base
      # Postfix format: [+|-]identifier
      # + means "after" (hotfix)
      # - means "before" (prerelease)
      # No postfix is in the middle

      def self.parse(value, _definition)
        return nil if value.nil? || value.empty?

        prefix = value[0]
        identifier = value[1..]

        { prefix: prefix, identifier: identifier }
      end

      def self.to_comparable(value, _definition)
        return 0 if value.nil?

        # Ordering: none (0) < + (1) < - (2)
        case value[:prefix]
        when "+" then 1
        when "-" then 2
        else 0
        end
      end

      def self.format(value)
        return "" if value.nil?

        "#{value[:prefix]}#{value[:identifier]}"
      end

      def self.compare_postfixes(a, b)
        return 0 if a.nil? && b.nil?
        return -1 if a.nil? # No postfix < +postfix
        return 1 if b.nil?

        # Compare by prefix first
        prefix_cmp = to_comparable(a) <=> to_comparable(b)
        return prefix_cmp if prefix_cmp != 0

        # Same prefix, compare identifier lexicographically
        a[:identifier] <=> b[:identifier]
      end
    end
  end
end

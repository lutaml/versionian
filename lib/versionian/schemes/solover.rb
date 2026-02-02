# frozen_string_literal: true

module Versionian
  module Schemes
    class SoloVer < VersionScheme
      SOLO_PATTERN = /^(\d+)(([+-])([a-zA-Z0-9]+))?$/

      def initialize(name: :solover, description: "SoloVer single number with optional postfix")
        super
      end

      def parse(version_string)
        validate_version_string(version_string)

        match = version_string.match(SOLO_PATTERN)
        raise Errors::ParseError, "Invalid SoloVer format '#{version_string}'" unless match

        number = match[1].to_i
        postfix = match[2]
        prefix = match[3]
        identifier = match[4]

        components = [
          VersionComponent.new(
            name: :number,
            type: :integer,
            value: number,
            weight: 1
          )
        ]

        comparable_array = [number]

        if postfix
          components << VersionComponent.new(
            name: :postfix,
            type: :postfix,
            value: { prefix: prefix, identifier: identifier },
            weight: 1
          )

          # Store prefix order and identifier for comparison
          prefix_order = case prefix
                         when "+" then 1
                         when "-" then 2
                         else 0
                         end
          comparable_array << prefix_order
          comparable_array << identifier
        end

        VersionIdentifier.new(
          raw_string: version_string,
          scheme: self,
          components: components,
          comparable_array: comparable_array
        )
      end

      def compare_arrays(a, b)
        # Compare number first
        number_cmp = a[0] <=> b[0]
        return number_cmp if number_cmp != 0

        # Check if both have postfixes or both don't
        a_has_postfix = a.length > 1
        b_has_postfix = b.length > 1

        if !a_has_postfix && !b_has_postfix
          return 0
        elsif !a_has_postfix
          return -1 # No postfix < +postfix
        elsif !b_has_postfix
          return 1
        end

        # Both have postfixes, compare by prefix
        prefix_cmp = a[1] <=> b[1]
        return prefix_cmp if prefix_cmp != 0

        # Same prefix, compare identifier lexicographically
        a[2] <=> b[2]
      end

      def matches_range?(version_string, range)
        version_a = parse(version_string)
        version_b = parse(range.boundary) if range.boundary
        version_from = parse(range.from) if range.from
        version_to = parse(range.to) if range.to

        case range.type
        when :equals
          compare_arrays(version_a.comparable_array, version_b.comparable_array).zero?
        when :before
          compare_arrays(version_a.comparable_array, version_b.comparable_array).negative?
        when :after
          compare_arrays(version_a.comparable_array, version_b.comparable_array) >= 0
        when :between
          compare_arrays(version_a.comparable_array, version_from.comparable_array) >= 0 &&
            compare_arrays(version_a.comparable_array, version_to.comparable_array) <= 0
        end
      end

      def render(version)
        postfix_component = version.component(:postfix)
        if postfix_component&.value
          "#{version.component(:number).value}#{postfix_component.value[:prefix]}#{postfix_component.value[:identifier]}"
        else
          version.component(:number).value.to_s
        end
      end

      private

      def validate_version_string(version_string)
        raise Errors::InvalidVersionError, "Version string cannot be nil" if version_string.nil?
        raise Errors::InvalidVersionError, "Version string cannot be empty" if version_string.strip.empty?
      end
    end
  end
end

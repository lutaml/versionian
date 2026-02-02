# frozen_string_literal: true

module Versionian
  module Schemes
    class Composite < VersionScheme
      attr_reader :schemes, :fallback_scheme

      def initialize(schemes:, fallback_scheme:, name:, description: nil)
        super(name: name, description: description)
        @schemes = schemes
        @fallback_scheme = fallback_scheme # Default if no pattern matches
      end

      def parse(version_string)
        # Try each scheme in order
        @schemes.each do |scheme|
          next unless scheme.valid?(version_string)

          version = scheme.parse(version_string)
          # Wrap with composite metadata for cross-format comparison
          return wrap_with_comparable_array(version)
        end

        # Fallback to default scheme
        @fallback_scheme.parse(version_string)
      end

      def compare_arrays(a, b)
        # Direct array comparison (already normalized by wrap_with_comparable_array)
        a <=> b
      end

      def matches_range?(version_string, range)
        version = parse(version_string)
        comparable = version.comparable_array

        case range.type
        when :equals
          comparable == parse(range.boundary).comparable_array
        when :before
          comparable < parse(range.boundary).comparable_array
        when :after
          comparable >= parse(range.boundary).comparable_array
        when :between
          comparable >= parse(range.from).comparable_array &&
            comparable <= parse(range.to).comparable_array
        end
      end

      def render(version)
        version.raw_string
      end

      private

      def wrap_with_comparable_array(version)
        # Extract comparable array and normalize length
        base_array = version.comparable_array

        # Check if any component has compare_as directive
        compare_as_component = version.components.find { |c| c.definition&.compare_as }

        if compare_as_component && compare_as_component.definition.compare_as == "lowest"
          # Mark as lower priority than base versions
          # Prefix with a sentinel value that sorts lower than any normal component
          # For x.y.z-git{hash}: [-1, 1, 2, 3, hash_value]
          # This sorts lower than [0, 1, 2, 3, 0] (standard x.y.z)
          [-1] + base_array
        elsif compare_as_component && compare_as_component.definition.compare_as == "highest"
          # Mark as higher priority than base versions
          [1] + base_array
        else
          # Standard comparison
          # Pad with zeros to normalize length
          max_length = 5
          padded = [0] + base_array + [0] * (max_length - base_array.length)
          padded.first(max_length + 1)
        end
      end
    end
  end
end

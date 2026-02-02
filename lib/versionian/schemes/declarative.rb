# frozen_string_literal: true

require_relative '../parsers/declarative'
require_relative '../version_scheme'

module Versionian
  module Schemes
    # Declarative version scheme that uses segment definitions instead of regex patterns.
    # This provides implementation independence and better performance than regex-based schemes.
    class Declarative < VersionScheme
      attr_reader :component_definitions, :parser

      # Initialize a new declarative scheme.
      #
      # @param name [Symbol] The name of the scheme
      # @param component_definitions [Array<ComponentDefinition, Hash>] Ordered segment definitions
      # @param description [String] Optional description of the scheme
      def initialize(name:, component_definitions:, description: nil)
        super(name: name, description: description)
        # Convert hash definitions to ComponentDefinition objects
        @component_definitions = component_definitions.map do |defn|
          defn.is_a?(Hash) ? ComponentDefinition.from_hash(defn) : defn
        end
        @parser = Parsers::Declarative.new(@component_definitions)
      end

      # Parse a version string into component values.
      #
      # @param version_string [String] The version string to parse
      # @return [Hash] Component values keyed by component name
      # @raise [Errors::ParseError] If the version string doesn't match the schema
      def parse(version_string)
        component_values = @parser.parse(version_string)
        build_version_object(version_string, component_values)
      end

      # Check if a version string matches this scheme.
      #
      # @param version_string [String]
      # @return [Boolean]
      def valid?(version_string)
        @parser.match?(version_string)
      end

      # Check if this scheme supports a given version string.
      #
      # @param version_string [String]
      # @return [Boolean]
      def supports?(version_string)
        valid?(version_string)
      end

      # Compare two version strings.
      #
      # @param a [String] First version string
      # @param b [String] Second version string
      # @return [Integer] -1, 0, or 1
      def compare(a, b)
        version_a = parse(a)
        version_b = parse(b)
        version_a <=> version_b
      end

      # Check if a version string matches a range.
      #
      # @param version_string [String] The version string to check
      # @param range [VersionRange] The range to check against
      # @return [Boolean]
      def matches_range?(version_string, range)
        version = parse(version_string)
        range.includes?(version)
      end

      # Render a version object back to a string.
      #
      # @param version [Version] The version object to render
      # @return [String] The rendered version string
      def render(version)
        version.raw_string
      end

      private

      # Build a Version object from component values.
      #
      # @param raw_string [String] The original version string
      # @param component_values [Hash] Parsed component values
      # @return [VersionIdentifier] The version object
      def build_version_object(raw_string, component_values)
        # Build comparable array from component values
        comparable_array = build_comparable_array(component_values)

        # Build component objects
        components = component_values.map do |name, value|
          definition = @component_definitions.find { |d| d.name == name }
          build_component_object(name, value, definition)
        end

        VersionIdentifier.new(
          raw_string: raw_string,
          scheme: self,
          components: components,
          comparable_array: comparable_array
        )
      end

      # Build a comparable array from component values.
      #
      # @param component_values [Hash] Parsed component values
      # @return [Array] Comparable array
      def build_comparable_array(component_values)
        # Build array based on component definitions order
        @component_definitions.map do |definition|
          value = component_values[definition.name]
          next if value.nil? # Skip optional components that weren't parsed

          component_type = ComponentTypes.resolve(definition.type)
          component_type.to_comparable(value, definition)
        end.compact
      end

      # Build a component object from a parsed value.
      #
      # @param name [Symbol] Component name
      # @param value [Object] Parsed value
      # @param definition [ComponentDefinition] Component definition
      # @return [VersionComponent] The component object
      def build_component_object(name, value, definition)
        VersionComponent.new(
          name: name,
          type: definition.type,
          value: value,
          weight: definition.weight || 1
        )
      end
    end
  end
end

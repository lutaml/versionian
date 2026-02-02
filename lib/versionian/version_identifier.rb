# frozen_string_literal: true

module Versionian
  class VersionIdentifier
    include Comparable

    attr_reader :raw_string, :scheme, :components, :comparable_array

    def initialize(raw_string:, scheme:, components:, comparable_array:)
      @raw_string = raw_string
      @scheme = scheme
      @components = components.freeze
      @comparable_array = comparable_array.freeze
      freeze
    end

    def <=>(other)
      raise ArgumentError, "Cannot compare versions from different schemes" unless @scheme == other.scheme

      @scheme.compare_arrays(@comparable_array, other.comparable_array)
    end

    def component(name)
      @components.find { |c| c.name == name }
    end

    def matches_range?(range)
      @scheme.matches_range?(@raw_string, range)
    end

    def to_s
      @scheme.render(self)
    end

    def inspect
      "#<Versionian::VersionIdentifier #{@raw_string} scheme=#{@scheme.name}>"
    end

    # Build a version programmatically from component values
    #
    # @param scheme [VersionScheme] The scheme to use for this version
    # @param components [Hash] Hash of component_name => value pairs
    # @return [VersionIdentifier] A new version identifier object
    #
    # @example
    #   scheme = Versionian.get_scheme(:semantic)
    #   version = Versionian::VersionIdentifier.build(
    #     scheme: scheme,
    #     components: { major: 1, minor: 2, patch: 3 }
    #   )
    def self.build(scheme:, components:)
      # Build raw_string from components using format_template if available
      raw_string = if scheme.format_template
                     render_from_template(scheme.format_template, scheme.component_definitions, components)
                   else
                     # Fallback: join components with dots
                     components.map { |_name, value| value.to_s }.join(".")
                   end

      # Build component objects
      component_objects = components.map do |name, value|
        comp_def = scheme.component_definitions.find { |cd| cd.name == name.to_sym }

        VersionComponent.new(
          name: name.to_sym,
          type: comp_def&.type || :string,
          value: value,
          weight: comp_def&.weight || 1,
          values: comp_def&.values || [],
          order: comp_def&.order || [],
          definition: comp_def
        )
      end

      # Build comparable_array
      # Special handling for Semantic scheme: use Gem::Version for comparison
      comparable_array = if scheme.is_a?(Schemes::Semantic)
                           require "rubygems/version"
                           version_str = components.map { |_name, value| value.to_s }.join(".")
                           [::Gem::Version.new(version_str)]
                         else
                           component_objects.map do |comp|
                             type = ComponentTypes.resolve(comp.type)
                             type.to_comparable(comp.value, comp)
                           end
                         end

      new(
        raw_string: raw_string,
        scheme: scheme,
        components: component_objects,
        comparable_array: comparable_array
      )
    end

    def self.render_from_template(format_template, _component_definitions, components)
      result = format_template.dup

      # Process optional segments []
      loop do
        match = result.match(/\[([^\[\]]+)\]/)
        break unless match

        segment_content = match[1]
        has_value = segment_content.scan(/\{(\w+)\}/).any? { |name| components.key?(name.first.to_sym) }

        result = result.sub(match[0], has_value ? segment_content : "")
      end

      # Replace component placeholders
      components.each do |name, value|
        placeholder = "{#{name}}"
        result = result.gsub(placeholder, value.to_s)
      end

      result
    end
  end
end

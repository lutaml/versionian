# frozen_string_literal: true

module Versionian
  class VersionScheme
    attr_reader :name, :description, :format_template, :component_definitions

    def initialize(name:, description: nil, format_template: nil, component_definitions: [])
      @name = name
      @description = description
      @format_template = format_template
      @component_definitions = component_definitions
    end

    # Abstract methods
    def parse(version_string)
      raise NotImplementedError, "#{self.class} must implement #parse"
    end

    def render(version)
      version.raw_string
    end

    # Default comparison (can be overridden)
    def compare_arrays(a, b)
      a <=> b
    end

    def compare(a, b)
      version_a = parse(a)
      version_b = parse(b)
      version_a <=> version_b
    end

    def matches_range?(version_string, range)
      version = parse(version_string)
      version.matches_range?(range)
    end

    def valid?(version_string)
      parse(version_string)
      true
    rescue Errors::InvalidVersionError, Errors::ParseError
      false
    end

    # Alias for valid? - check if this scheme supports a version string
    def supports?(version_string)
      valid?(version_string)
    end

    # Build a version programmatically from component values
    #
    # @param components [Hash] Hash of component_name => value pairs
    # @return [VersionIdentifier] A new version identifier object
    #
    # @example
    #   scheme.build(major: 1, minor: 2, patch: 3)
    def build(**components)
      VersionIdentifier.build(scheme: self, components: components)
    end

    def ==(other)
      return false unless other.is_a?(VersionScheme)

      @name == other.name
    end
  end
end

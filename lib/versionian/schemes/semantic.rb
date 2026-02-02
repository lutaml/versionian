# frozen_string_literal: true

require "rubygems/version"

module Versionian
  module Schemes
    # Autoload all scheme classes
    autoload :Pattern, "versionian/schemes/pattern"
    autoload :Declarative, "versionian/schemes/declarative"
    autoload :CalVer, "versionian/schemes/calver"
    autoload :Composite, "versionian/schemes/composite"
    autoload :SoloVer, "versionian/schemes/solover"
    autoload :WendtVer, "versionian/schemes/wendtver"

    class Semantic < VersionScheme
      # SemVer pattern: MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
      # Must be exactly X.Y or X.Y.Z format where X, Y, Z are non-negative integers
      # CalVer formats like YYYY.MM.DD should not match (year is 4 digits)
      SEMVER_PATTERN = /\A\d{1,5}\.\d{1,5}(?:\.\d{1,5})?(?:-[\w.]+)?(?:\+[\w.]+)?\z/

      def initialize(name: :semantic, description: "Semantic versioning (semver.org)")
        component_definitions = [
          { name: :major, type: :integer },
          { name: :minor, type: :integer },
          { name: :patch, type: :integer, optional: true }
        ].map { |d| d.is_a?(Hash) ? ComponentDefinition.from_hash(d) : ComponentDefinition.new(**d) }

        super(
          name: name,
          description: description,
          component_definitions: component_definitions
        )
      end

      def parse(version_string)
        validate_version_string(version_string)

        # Strip build metadata for Gem::Version compatibility
        version_without_build = version_string.gsub(/\+.*$/, "")
        gem_version = ::Gem::Version.new(version_without_build)
        components = build_components(version_string, gem_version)
        comparable_array = [gem_version] # Gem::Version is directly comparable

        VersionIdentifier.new(
          raw_string: version_string,
          scheme: self,
          components: components,
          comparable_array: comparable_array
        )
      rescue ArgumentError => e
        raise Errors::InvalidVersionError, "Invalid semantic version '#{version_string}': #{e.message}"
      end

      def compare_arrays(a, b)
        # Gem::Version handles comparison
        a <=> b
      end

      def matches_range?(version_string, range)
        version = parse(version_string)
        gem_version = version.comparable_array.first

        case range.type
        when :equals
          gem_version == ::Gem::Version.new(range.boundary.gsub(/\+.*$/, ""))
        when :before
          gem_version < ::Gem::Version.new(range.boundary.gsub(/\+.*$/, ""))
        when :after
          gem_version >= ::Gem::Version.new(range.boundary.gsub(/\+.*$/, ""))
        when :between
          gem_version >= ::Gem::Version.new(range.from.gsub(/\+.*$/, "")) &&
            gem_version <= ::Gem::Version.new(range.to.gsub(/\+.*$/, ""))
        end
      end

      def valid?(version_string)
        return false if version_string.nil? || version_string.strip.empty?
        return false unless version_string =~ SEMVER_PATTERN

        # Check if this looks like a CalVer date (first component is a 4-digit year)
        # Exclude versions like 2024.01.15 that look like dates
        first_component = version_string.split(/[-.+]/).first
        if first_component =~ /^\d{4}$/ && first_component.to_i.between?(1900, 2100)
          # This looks like a year, not a semantic version
          return false
        end

        # Try to parse it
        super
      end

      private

      def build_components(version_string, gem_version)
        # Extract components from version string
        version_string.split(/[+-]/).first.split(".")
        components = []

        components << VersionComponent.new(
          name: :major,
          type: :integer,
          value: gem_version.segments[0] || 0,
          weight: 1,
          definition: @component_definitions[0]
        )

        components << VersionComponent.new(
          name: :minor,
          type: :integer,
          value: gem_version.segments[1] || 0,
          weight: 1,
          definition: @component_definitions[1]
        )

        if gem_version.segments.length >= 3
          components << VersionComponent.new(
            name: :patch,
            type: :integer,
            value: gem_version.segments[2],
            weight: 1,
            definition: @component_definitions[2]
          )
        end

        components
      end

      def validate_version_string(version_string)
        return unless version_string.nil? || version_string.strip.empty?

        raise Errors::InvalidVersionError,
              "Version string cannot be empty"
      end
    end
  end
end

# frozen_string_literal: true

module Versionian
  module Schemes
    class WendtVer < VersionScheme
      WENDT_PATTERN = /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/

      # WendtVer uses auto-incrementing components with carryover
      # Format: major.minor.patch.build
      # When build reaches 999, it resets to 0 and increments patch
      # When patch reaches 99, it resets to 0 and increments minor
      # When minor reaches 99, it resets to 0 and increments major

      MAX_VALUES = { build: 999, patch: 99, minor: 99, major: Float::INFINITY }.freeze

      def initialize(name: :wendtver, description: "WendtVer auto-incrementing with carryover")
        super
      end

      def parse(version_string)
        validate_version_string(version_string)

        match = version_string.match(WENDT_PATTERN)
        raise Errors::ParseError, "Invalid WendtVer format '#{version_string}'" unless match

        major = match[1].to_i
        minor = match[2].to_i
        patch = match[3].to_i
        build = match[4].to_i

        validate_ranges(major, minor, patch, build)

        components = [
          VersionComponent.new(name: :major, type: :integer, value: major, weight: 1),
          VersionComponent.new(name: :minor, type: :integer, value: minor, weight: 1),
          VersionComponent.new(name: :patch, type: :integer, value: patch, weight: 1),
          VersionComponent.new(name: :build, type: :integer, value: build, weight: 1)
        ]

        comparable_array = [major, minor, patch, build]

        VersionIdentifier.new(
          raw_string: version_string,
          scheme: self,
          components: components,
          comparable_array: comparable_array
        )
      end

      def compare_arrays(a, b)
        # Standard lexicographic comparison
        a <=> b
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
        [version.component(:major).value,
         version.component(:minor).value,
         version.component(:patch).value,
         version.component(:build).value].join(".")
      end

      # Increment a version by one position
      def increment(version_string, position = :build)
        version = parse(version_string)
        major = version.component(:major).value
        minor = version.component(:minor).value
        patch = version.component(:patch).value
        build = version.component(:build).value

        case position
        when :build
          build += 1
          if build > MAX_VALUES[:build]
            build = 0
            patch += 1
            if patch > MAX_VALUES[:patch]
              patch = 0
              minor += 1
              if minor > MAX_VALUES[:minor]
                minor = 0
                major += 1
              end
            end
          end
        when :patch
          patch += 1
          if patch > MAX_VALUES[:patch]
            patch = 0
            minor += 1
            if minor > MAX_VALUES[:minor]
              minor = 0
              major += 1
            end
          end
        when :minor
          minor += 1
          if minor > MAX_VALUES[:minor]
            minor = 0
            major += 1
          end
        when :major
          major += 1
        end

        "#{major}.#{minor}.#{patch}.#{build}"
      end

      private

      def validate_version_string(version_string)
        raise Errors::InvalidVersionError, "Version string cannot be nil" if version_string.nil?
        raise Errors::InvalidVersionError, "Version string cannot be empty" if version_string.strip.empty?
      end

      def validate_ranges(_major, minor, patch, build)
        raise Errors::ParseError, "Minor must be 0-99" unless minor.between?(0, 99)
        raise Errors::ParseError, "Patch must be 0-99" unless patch.between?(0, 99)
        raise Errors::ParseError, "Build must be 0-999" unless build.between?(0, 999)
      end
    end
  end
end

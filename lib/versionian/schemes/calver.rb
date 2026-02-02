# frozen_string_literal: true

module Versionian
  module Schemes
    class CalVer < VersionScheme
      # Format patterns with explicit format templates for rendering
      FORMAT_PATTERNS = {
        # Date-based formats with standard separators
        "YYYY.MM.DD" => {
          pattern: '^(\d{4})\.(\d{2})\.(\d{2})$',
          format: "{year}.{month}.{day}"
        },
        "YYYY.MM" => {
          pattern: '^(\d{4})\.(\d{2})$',
          format: "{year}.{month}"
        },
        "YYYY.WW" => {
          pattern: '^(\d{4})\.(\d{2})$',
          format: "{year}.{week}"
        },
        "YY.MM.DD" => {
          pattern: '^(\d{2})\.(\d{2})\.(\d{2})$',
          format: "{year}.{month}.{day}"
        },
        "YY.MM" => {
          pattern: '^(\d{2})\.(\d{2})$',
          format: "{year}.{month}"
        },
        "YY.WW" => {
          pattern: '^(\d{2})\.(\d{2})$',
          format: "{year}.{week}"
        }
      }.freeze

      attr_reader :format, :pattern_scheme

      def initialize(format: "YYYY.MM.DD", name: :calver, description: nil)
        # Normalize format - 0M and 0W are just formatting, use MM and WW
        normalized_format = format.gsub("0M", "MM").gsub("0W", "WW")

        config = FORMAT_PATTERNS[normalized_format] || FORMAT_PATTERNS["YYYY.MM.DD"]
        desc = description || "Calendar versioning (#{normalized_format})"

        component_definitions = build_component_definitions(normalized_format)

        super(name: name, description: desc)
        @format = normalized_format
        @pattern_scheme = Pattern.new(
          name: name,
          pattern: config[:pattern],
          component_definitions: component_definitions,
          format_template: config[:format],
          description: desc
        )
      end

      def parse(version_string)
        @pattern_scheme.parse(version_string)
      end

      def compare_arrays(a, b)
        @pattern_scheme.compare_arrays(a, b)
      end

      def matches_range?(version_string, range)
        @pattern_scheme.matches_range?(version_string, range)
      end

      def render(version)
        @pattern_scheme.render(version)
      end

      private

      def build_component_definitions(format)
        definitions = []

        # Year component (2 or 4 digits)
        definitions << { name: :year, type: :date_part, subtype: :year }

        # Month component
        definitions << { name: :month, type: :date_part, subtype: :month } if format.include?("MM")

        # Day component
        definitions << { name: :day, type: :date_part, subtype: :day } if format.include?("DD")

        # Week component
        definitions << { name: :week, type: :date_part, subtype: :week } if format.include?("WW")

        definitions
      end
    end
  end
end

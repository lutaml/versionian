# frozen_string_literal: true

module Versionian
  module Schemes
    class Pattern < VersionScheme
      attr_reader :pattern, :pattern_regex

      # Format template uses placeholders like {major}, {minor}, etc.
      # Example: "{major}.{minor}.{patch}" or "{year}.{month}-{build}"

      def initialize(name:, pattern:, component_definitions:, format_template: nil, description: nil)
        # Process component_definitions first (convert hashes to ComponentDefinition objects)
        processed_definitions = component_definitions.map do |d|
          d.is_a?(Hash) ? ComponentDefinition.from_hash(d) : ComponentDefinition.new(**d)
        end
        validate_component_definitions!(processed_definitions)

        # Derive or use provided format_template
        template = format_template || derive_format_template(pattern)

        # Call super with all parameters
        super(
          name: name,
          description: description,
          format_template: template,
          component_definitions: processed_definitions
        )

        @pattern = pattern
        @pattern_regex = compile_and_validate_pattern(pattern)
      end

      def validate_component_definitions!(definitions = @component_definitions)
        raise Errors::InvalidSchemeError, "No component definitions provided" if definitions.empty?
      end

      def parse(version_string)
        validate_version_string(version_string)

        match = version_string.match(@pattern_regex)
        raise Errors::ParseError, "Version '#{version_string}' does not match pattern #{@pattern}" unless match

        components = extract_components(match)
        validate_component_count(match.captures.length)

        comparable_array = build_comparable_array(components)

        VersionIdentifier.new(
          raw_string: version_string,
          scheme: self,
          components: components,
          comparable_array: comparable_array
        )
      end

      def compare_arrays(a, b)
        # Lexicographic comparison
        max_len = [a.length, b.length].max
        max_len.times do |i|
          a_val = a[i]
          b_val = b[i]

          # Handle nil values (optional components)
          a_val = 0 if a_val.nil?
          b_val = 0 if b_val.nil?

          cmp = a_val <=> b_val
          return cmp if cmp != 0
        end

        a.length <=> b.length
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
        # If no format template, return raw_string
        return version.raw_string unless @format_template

        # Reconstruct version from components using format template
        # Format template supports optional segments with [] syntax
        # Example: "{major}.{minor}.{patch}[.{patchlevel}]"
        #          "{major}.{minor}.{patch}[-{stage}-{iteration}]"
        result = @format_template.dup

        # First, handle optional segments marked with []
        # Process from innermost to outermost to handle nested optionals
        loop do
          # Find innermost optional segment
          match = result.match(/\[([^\[\]]+)\]/)
          break unless match

          optional_segment = match[1]
          placeholder = match[0]

          # Check if any component placeholders in this segment have values
          has_value = false
          optional_segment.scan(/\{(\w+)\}/) do |component_name|
            component = version.component(component_name.first.to_sym)
            has_value = true if component
          end

          # Replace with content if has value, empty string otherwise
          replacement = has_value ? optional_segment : ""
          result = result.sub(placeholder, replacement)
        end

        # Then replace component values for all placeholders
        @component_definitions.each do |comp_def|
          component = version.component(comp_def.name)
          type = ComponentTypes.resolve(comp_def.type)

          # Build placeholder string, converting symbol name to string
          placeholder = "{#{comp_def.name.to_s}}"

          if component
            formatted_value = type.format(component.value)
            result = result.gsub(placeholder, formatted_value)
          else
            # Remove empty placeholder
            result = result.gsub(placeholder, "")
          end
        end

        # puts "After component replacement: #{result.inspect}"

        # Clean up any remaining empty optional segment markers
        # e.g., "[-{stage}-{iteration}]" where both stage and iteration are nil becomes "[-]"
        result = result.gsub(/\[-\]/, "").gsub(/\[-/, "-").gsub(/-\]/, "-")

        # Clean up any double separators or leading/trailing separators
        result = result.gsub(/\.+/, ".").gsub(/^-/, "").gsub(/-$/, "").gsub(/^\.+/, "").gsub(/\.+$/, "")
      end

      private

      def compile_and_validate_pattern(pattern_str)
        # Basic ReDoS protection
        # Check for dangerous patterns that can cause catastrophic backtracking
        if pattern_str.include?("\\d+*") || pattern_str.include?('\d+*')
          raise Errors::InvalidSchemeError, "Pattern may cause catastrophic backtracking"
        end

        if pattern_str =~ /\(\([^(]*\*\)[^)]*\*\)/ || pattern_str =~ /\(\([^(]*\+\)[^)]*\+\)/
          raise Errors::InvalidSchemeError, "Pattern may cause catastrophic backtracking"
        end

        raise Errors::InvalidSchemeError, "Pattern has too many nested quantifiers" if pattern_str.scan(/\{/).length > 5

        Regexp.new(pattern_str)
      end

      def derive_format_template(pattern_str)
        # Derive format template from pattern by replacing capture groups with placeholders
        # Pattern: ^(\d+)\.(\d+)\.(\d+)$ -> Format: {name1}.{name2}.{name3}

        # Find all capture groups and their positions
        pattern_str.gsub(/^\^|\$$/, "") # Remove anchors

        # Replace each capture group with a placeholder
        # We need to track which capture group corresponds to which component
        # Since @component_definitions might not be set yet, we defer to a simpler approach

        # For now, just store the pattern and use raw_string for rendering
        # Users can provide explicit format_template if they want custom rendering
        nil
      end

      def extract_components(match)
        @component_definitions.each_with_index.map do |comp_def, index|
          raw_value = match[index + 1] # Skip full match

          # Handle optional components
          if raw_value.nil?
            next nil if comp_def.optional

            # Skip optional components that didn't match

            raise Errors::ParseError, "Required component '#{comp_def.name}' is missing"

          end

          type = ComponentTypes.resolve(comp_def.type)
          parsed_value = type.parse(raw_value, comp_def)

          VersionComponent.new(
            name: comp_def.name,
            type: comp_def.type,
            value: parsed_value,
            weight: comp_def.weight || 1,
            values: comp_def.values,
            order: comp_def.order || [],
            definition: comp_def
          )
        end.compact # Remove nils from optional components
      end

      def build_comparable_array(components)
        components.map do |component|
          next if component.definition&.ignore_in_comparison

          type = ComponentTypes.resolve(component.type)
          type.to_comparable(component.value, component)
        end.compact
      end

      def validate_component_count(capture_count)
        # For patterns with optional components, we validate during extraction
        # The capture_count here is total groups, but optional ones may be nil
        # This is validated in extract_components where we check required components
      end

      def validate_version_string(version_string)
        return unless version_string.nil? || version_string.strip.empty?

        raise Errors::InvalidVersionError,
              "Version string cannot be empty"
      end
    end
  end
end

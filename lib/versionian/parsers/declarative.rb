# frozen_string_literal: true

module Versionian
  module Parsers
    # Parses version strings based on declarative segment definitions.
    # Uses a state machine approach instead of regex for implementation independence.
    class Declarative
      attr_reader :segment_definitions

      # @param segment_definitions [Array<ComponentDefinition>] Ordered segment definitions
      def initialize(segment_definitions)
        @segment_definitions = segment_definitions
        validate_definitions!
      end

      # Parse a version string into component values.
      #
      # @param version_string [String] The version string to parse
      # @return [Hash] Component values keyed by component name
      # @raise [Errors::ParseError] If the version string doesn't match the schema
      def parse(version_string)
        raise Errors::ParseError, "Version string cannot be empty" if version_string.nil? || version_string.empty?

        position = 0
        results = {}

        @segment_definitions.each_with_index do |segment, index|
          # For optional segments with prefix, check if the prefix is present
          # If the prefix was used as a boundary marker by the previous segment,
          # we need to handle this case specially
          if segment.optional && segment.prefix
            if position >= version_string.length
              results[segment.name] = nil
              next
            end

            # Check if the defined prefix is present at the current position
            prefix_at_position = version_string[position, segment.prefix.length] == segment.prefix

            # Check if the prefix was just before our current position
            # (meaning it was used as a boundary marker)
            prefix_before_position = position >= segment.prefix.length &&
              version_string[position - segment.prefix.length, segment.prefix.length] == segment.prefix

            # For include_prefix_in_value, check if we're at a prefix-like character
            prefix_like_char = segment.include_prefix_in_value &&
              ["+", "-"].include?(version_string[position, 1])

            prefix_present = prefix_at_position || prefix_before_position || prefix_like_char

            unless prefix_present
              results[segment.name] = nil
              next
            end

            # If prefix was before our position, we're already past it, so don't consume again
            # If prefix is at our position, consume it (unless include_prefix_in_value)
            if prefix_at_position
              unless segment.include_prefix_in_value
                position += segment.prefix.length
              end
            end
          end

          # Find where this segment ends (look ahead to next segment's markers)
          end_pos = find_segment_end_position(version_string, position, index)

          # Extract raw value
          raw_value = version_string[position...end_pos]

          if raw_value.nil? || raw_value.empty?
            if segment.optional
              results[segment.name] = nil
              next
            else
              raise Errors::ParseError,
                    "Required segment '#{segment.name}' is missing or empty"
            end
          end

          # Parse the value
          component_type = ComponentTypes.resolve(segment.type)
          parsed_value = component_type.parse(raw_value, segment)
          results[segment.name] = parsed_value

          # Advance position to end of this segment's value
          position = end_pos

          # After processing this segment, consume the separator for the next segment
          # The separator is defined on the CURRENT segment and comes BEFORE the next segment
          if segment.separator && !segment.separator.empty?
            if position < version_string.length
              if version_string[position, segment.separator.length] == segment.separator
                position += segment.separator.length
              end
              # If separator not found at position, the next segment will handle it
            end
          end
        end

        # Check that we consumed the entire string
        if position < version_string.length
          remaining = version_string[position..-1]
          raise Errors::ParseError,
                "Unexpected trailing content after parsing: '#{remaining}'"
        end

        results
      end

      # Check if a version string matches this schema.
      #
      # @param version_string [String]
      # @return [Boolean]
      def match?(version_string)
        parse(version_string)
        true
      rescue Errors::ParseError, Errors::InvalidVersionError
        false
      end

      private

      # Find the end position of this segment in the version string.
      #
      # The end position is determined by finding the earliest occurrence of:
      # - This segment's own separator (if any) - the separator comes AFTER the value
      # - The next segment's prefix (if any) - prefix comes BEFORE the next value
      # - The next segment's separator (if this segment has no separator)
      # - End of string (fallback)
      #
      # @param string [String] The version string
      # @param position [Integer] Current position in the string
      # @param segment_index [Integer] Index of current segment
      # @return [Integer] End position of this segment
      def find_segment_end_position(string, position, segment_index)
        candidates = [string.length]
        current_segment = @segment_definitions[segment_index]

        # Check for current segment's own separator (comes after this segment's value)
        if current_segment.separator && !current_segment.separator.empty?
          sep_pos = string.index(current_segment.separator, position)
          candidates << sep_pos if sep_pos && sep_pos >= position
        end

        # Look for next segment's markers (separators and prefixes)
        ((segment_index + 1)...@segment_definitions.length).each do |next_idx|
          next_segment = @segment_definitions[next_idx]

          # Check for next segment's separator (always valid as a boundary)
          if next_segment.separator && !next_segment.separator.empty?
            sep_pos = string.index(next_segment.separator, position)
            candidates << sep_pos if sep_pos && sep_pos >= position
          end

          # Check for next segment's prefix (always valid as a boundary)
          if next_segment.prefix && !next_segment.prefix.empty?
            # Check if the prefix exists in the remaining string (from position onwards)
            remaining = string[position..]
            found_prefix = false

            if remaining
              prefix_index_in_remaining = remaining.index(next_segment.prefix)
              if prefix_index_in_remaining
                # Calculate the actual position in the full string
                actual_prefix_pos = position + prefix_index_in_remaining
                candidates << actual_prefix_pos
                found_prefix = true
              end
            end

            # For include_prefix_in_value segments, also check for alternative prefixes
            if next_segment.include_prefix_in_value
              ["+", "-"].each do |alt_prefix|
                if alt_prefix != next_segment.prefix
                  alt_index_in_remaining = remaining&.index(alt_prefix)
                  if alt_index_in_remaining
                    candidates << (position + alt_index_in_remaining)
                    found_prefix = true
                  end
                end
              end
            end

            # Only stop looking if we found a prefix in the remaining string
            break if found_prefix
          end
        end

        candidates.compact.min
      end

      def validate_definitions!
        @segment_definitions.each do |segment|
          raise Errors::InvalidSchemeError, "segment name required" unless segment.name
          raise Errors::InvalidSchemeError, "segment type required" unless segment.type
        end

        # Validate that optional segments (after the first) have a prefix
        @segment_definitions.each_with_index do |segment, index|
          next unless segment.optional
          next if index.zero? # First segment doesn't need separator before it

          # Optional segment must have prefix (to identify its presence)
          # Separator alone is not enough because optional segments are optional
          if segment.prefix.nil?
            raise Errors::InvalidSchemeError,
                  "Optional segment '#{segment.name}' must have prefix or separator"
          end
        end
      end
    end
  end
end

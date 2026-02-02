# frozen_string_literal: true

module Versionian
  module ComponentTypes
    class DatePart < Base
      RANGES = {
        year: [1, 9999],
        month: [1, 12],
        day: [1, 31],
        week: [1, 53],
        hour: [0, 23],
        minute: [0, 59],
        second: [0, 59]
      }.freeze

      def self.parse(value, definition)
        return definition.default.to_i if value.nil? || value.empty?

        int_val = Kernel.Integer(value)

        subtype = definition.subtype
        if subtype && RANGES.key?(subtype.to_sym)
          min, max = RANGES[subtype.to_sym]
          unless int_val.between?(min, max)
            raise Errors::ParseError, "Invalid #{subtype} '#{int_val}'. Must be between #{min} and #{max}"
          end
        end

        int_val
      end

      def self.to_comparable(value, _definition)
        value
      end

      def self.format(value)
        value.to_s.rjust(2, "0")
      end
    end
  end
end

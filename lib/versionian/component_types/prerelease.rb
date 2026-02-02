# frozen_string_literal: true

module Versionian
  module ComponentTypes
    class Prerelease < Base
      def self.parse(value, _definition)
        return nil if value.nil? || value.empty?

        # Split by dots: "alpha.1" => ["alpha", "1"]
        value.split(".").map do |part|
          if part =~ /^\d+$/
            part.to_i
          else
            part.to_sym
          end
        end
      end

      def self.to_comparable(value, _definition)
        # Compare according to SemVer rules
        # nil > any prerelease
        return [1] if value.nil?

        value
      end

      def self.format(value)
        return "" if value.nil?

        value.map(&:to_s).join(".")
      end

      # Custom comparison for SemVer prerelease rules
      def self.compare_prerelease_arrays(a, b)
        return 0 if a.nil? && b.nil?
        return 1 if a.nil? # nil > any prerelease
        return -1 if b.nil?

        max_len = [a.length, b.length].max
        max_len.times do |i|
          a_val = a[i]
          b_val = b[i]

          # Missing identifier = lower priority
          return -1 if a_val.nil?
          return 1 if b_val.nil?

          # Numeric < alphanumeric
          a_is_num = a_val.is_a?(Integer)
          b_is_num = b_val.is_a?(Integer)

          if a_is_num && !b_is_num
            return -1
          elsif !a_is_num && b_is_num
            return 1
          elsif a_is_num && b_is_num
            cmp = a_val <=> b_val
            return cmp if cmp != 0
          else
            cmp = a_val.to_s <=> b_val.to_s
            return cmp if cmp != 0
          end
        end

        # All equal up to here, shorter is lower priority
        a.length <=> b.length
      end
    end
  end
end

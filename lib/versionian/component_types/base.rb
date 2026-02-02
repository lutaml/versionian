# frozen_string_literal: true

module Versionian
  module ComponentTypes
    class Base
      def self.parse(value, definition)
        raise NotImplementedError, "#{self} must implement .parse"
      end

      def self.to_comparable(value, definition)
        raise NotImplementedError, "#{self} must implement .to_comparable"
      end

      def self.format(value)
        raise NotImplementedError, "#{self} must implement .format"
      end
    end
  end
end

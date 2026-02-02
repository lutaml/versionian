# frozen_string_literal: true

module Versionian
  class VersionRange
    attr_reader :type, :scheme

    def initialize(type, scheme, **boundaries)
      @type = type
      @scheme = scheme
      @boundaries = boundaries.freeze
      validate!
      freeze
    end

    def boundary
      @boundaries[:version]
    end

    def from
      @boundaries[:from]
    end

    def to
      @boundaries[:to]
    end

    def matches?(version_string)
      @scheme.matches_range?(version_string, self)
    end

    def includes?(version)
      if version.is_a?(Version)
        matches?(version.raw_string)
      else
        matches?(version)
      end
    end

    def to_s
      case @type
      when :equals then "== #{@boundaries[:version]}"
      when :before then "< #{@boundaries[:version]}"
      when :after then ">= #{@boundaries[:version]}"
      when :between then "#{@boundaries[:from]} - #{@boundaries[:to]}"
      end
    end

    private

    def validate!
      case @type
      when :equals, :before, :after
        raise ArgumentError, "#{@type} range requires :version" unless @boundaries[:version]
      when :between
        raise ArgumentError, "between range requires :from and :to" unless @boundaries[:from] && @boundaries[:to]
      else
        raise ArgumentError, "Unknown range type: #{@type}"
      end
    end
  end
end

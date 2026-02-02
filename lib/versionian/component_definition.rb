# frozen_string_literal: true

module Versionian
  class ComponentDefinition
    attr_reader :name, :type, :subtype, :values, :order, :weight, :optional, :ignore_in_comparison, :default,
                :compare_as, :separator, :prefix, :suffix, :min_count, :max_count, :validate, :include_prefix_in_value

    def initialize(**attrs)
      @name = attrs[:name]
      @type = attrs[:type]
      @subtype = attrs[:subtype]
      @values = attrs[:values] || []
      @order = attrs[:order] || []
      @weight = attrs[:weight] || 1
      @optional = attrs[:optional] || false
      @ignore_in_comparison = attrs[:ignore_in_comparison] || false
      @default = attrs[:default]
      @compare_as = attrs[:compare_as]
      @separator = attrs[:separator]
      @prefix = attrs[:prefix]
      @suffix = attrs[:suffix]
      @min_count = attrs[:min_count] || 1
      @max_count = attrs[:max_count] || 1
      @validate = attrs[:validate] || {}
      @include_prefix_in_value = attrs[:include_prefix_in_value] || false
      freeze
    end

    def self.from_hash(hash)
      new(
        name: hash["name"]&.to_sym || hash[:name],
        type: hash["type"]&.to_sym || hash[:type],
        subtype: hash["subtype"] || hash[:subtype],
        values: (hash["values"] || hash[:values] || []).map(&:to_sym),
        order: (hash["order"] || hash[:order] || []).map(&:to_sym),
        weight: hash["weight"] || hash[:weight],
        optional: hash["optional"] || hash[:optional],
        ignore_in_comparison: hash["ignore_in_comparison"] || hash[:ignore_in_comparison],
        default: hash["default"] || hash[:default],
        compare_as: hash["compare_as"] || hash[:compare_as],
        separator: hash["separator"] || hash[:separator],
        prefix: hash["prefix"] || hash[:prefix],
        suffix: hash["suffix"] || hash[:suffix],
        min_count: hash["min_count"] || hash[:min_count] || 1,
        max_count: hash["max_count"] || hash[:max_count] || 1,
        validate: hash["validate"] || hash[:validate] || {},
        include_prefix_in_value: hash["include_prefix_in_value"] || hash[:include_prefix_in_value]
      )
    end

    def validate!
      raise Errors::InvalidSchemeError, "name is required" unless @name
      raise Errors::InvalidSchemeError, "type is required" unless @type
    end

    # Check if this component definition defines a separator
    def has_separator?
      !@separator.nil? && !@separator.empty?
    end

    # Check if this component definition defines a prefix
    def has_prefix?
      !@prefix.nil? && !@prefix.empty?
    end

    # Check if this component definition defines a suffix
    def has_suffix?
      !@suffix.nil? && !@suffix.empty?
    end
  end
end

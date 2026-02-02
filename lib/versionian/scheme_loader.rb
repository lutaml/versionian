# frozen_string_literal: true

require "yaml"
require "psych"

module Versionian
  module Schemes
    autoload :Pattern, "versionian/schemes/pattern"
    autoload :CalVer, "versionian/schemes/calver"
    autoload :Composite, "versionian/schemes/composite"
  end

  class SchemeLoader
    ALLOWED_CLASSES = [Symbol, Integer, String, Array, Hash, TrueClass, FalseClass, NilClass].freeze

    class << self
      def from_yaml_file(path)
        yaml = File.read(path)
        from_yaml_string(yaml)
      end

      def from_yaml_string(yaml_string)
        data = Psych.safe_load(yaml_string, permitted_classes: ALLOWED_CLASSES, aliases: true)
        from_hash(data)
      rescue Psych::SyntaxError => e
        raise Errors::InvalidSchemeError, "Invalid YAML: #{e.message}"
      end

      def from_hash(data)
        case data["type"]&.to_sym
        when :declarative, "declarative"
          Schemes::Declarative.new(
            name: data["name"]&.to_sym,
            component_definitions: parse_component_definitions(data["components"]),
            description: data["description"]
          )
        when :pattern, "pattern"
          Schemes::Pattern.new(
            name: data["name"]&.to_sym,
            pattern: data["pattern"],
            component_definitions: parse_component_definitions(data["components"]),
            format_template: data["format_template"],
            description: data["description"]
          )
        when :calver, "calver"
          Schemes::CalVer.new(
            format: data["format"] || "YYYY.MM.DD",
            name: data["name"]&.to_sym || :calver,
            description: data["description"]
          )
        when :composite, "composite"
          parse_composite_scheme(data)
        else
          raise Errors::InvalidSchemeError, "Unknown scheme type: #{data["type"]}"
        end
      end

      private

      def parse_composite_scheme(data)
        sub_schemes = (data["schemes"] || []).map do |scheme_data|
          from_hash(scheme_data)
        end

        fallback = from_hash(data["fallback_scheme"]) if data["fallback_scheme"]

        Schemes::Composite.new(
          name: data["name"]&.to_sym,
          schemes: sub_schemes,
          fallback_scheme: fallback,
          description: data["description"]
        )
      end

      def parse_component_definitions(components_data)
        return [] unless components_data

        components_data.map do |comp|
          {
            name: comp["name"]&.to_sym,
            type: comp["type"]&.to_sym,
            subtype: comp["subtype"],
            values: (comp["values"] || []).map(&:to_sym),
            order: (comp["order"] || []).map(&:to_sym),
            weight: comp["weight"],
            optional: comp["optional"],
            ignore_in_comparison: comp["ignore_in_comparison"],
            default: comp["default"],
            compare_as: comp["compare_as"],
            separator: comp["separator"],
            prefix: comp["prefix"],
            suffix: comp["suffix"],
            min_count: comp["min_count"] || 1,
            max_count: comp["max_count"] || 1,
            validate: comp["validate"] || {},
            include_prefix_in_value: comp["include_prefix_in_value"]
          }.compact
        end
      end
    end
  end
end

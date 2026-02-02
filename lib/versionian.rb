# frozen_string_literal: true

require_relative "versionian/version"

# Require error classes (they have interdependent module definitions)
require_relative "versionian/errors/invalid_version_error"
require_relative "versionian/errors/invalid_scheme_error"
require_relative "versionian/errors/parse_error"

# Autoload models at the Versionian module level
module Versionian
  # Autoload models
  autoload :VersionComponent, "versionian/version_component"
  autoload :VersionIdentifier, "versionian/version_identifier"
  autoload :VersionScheme, "versionian/version_scheme"
  autoload :VersionRange, "versionian/version_range"
  autoload :ComponentDefinition, "versionian/component_definition"

  # Autoload component types module
  autoload :ComponentTypes, "versionian/component_types/registry"
  autoload :Parsers, "versionian/parsers/declarative"

  # Autoload schemes module
  autoload :Schemes, "versionian/schemes/semantic"

  # Autoload utilities
  autoload :SchemeRegistry, "versionian/scheme_registry"
  autoload :SchemeLoader, "versionian/scheme_loader"
  autoload :PrimitiveLibrary, "versionian/primitive_library"

  # Register built-in component types
  ComponentTypes.register(:integer, ComponentTypes::Integer)
  ComponentTypes.register(:float, ComponentTypes::Float)
  ComponentTypes.register(:enum, ComponentTypes::Enum)
  ComponentTypes.register(:string, ComponentTypes::String)
  ComponentTypes.register(:date_part, ComponentTypes::DatePart)
  ComponentTypes.register(:prerelease, ComponentTypes::Prerelease)
  ComponentTypes.register(:postfix, ComponentTypes::Postfix)
  ComponentTypes.register(:hash, ComponentTypes::Hash)

  class << self
    def scheme_registry
      @scheme_registry ||= SchemeRegistry.instance.tap do |registry|
        # Register built-in schemes
        registry.register(:semantic, Schemes::Semantic.new)
        registry.register(:calver, Schemes::CalVer.new)
        registry.register(:solover, Schemes::SoloVer.new)
        registry.register(:wendtver, Schemes::WendtVer.new)
      end
    end

    def register_scheme(name, scheme)
      scheme_registry.register(name, scheme)
    end

    def get_scheme(name)
      scheme_registry.get(name)
    end

    def detect_scheme(version_string)
      scheme_registry.detect_from(version_string)
    end
  end
end

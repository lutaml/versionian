# frozen_string_literal: true

module Versionian
  module ComponentTypes
    # Autoload component type classes
    autoload :Base, "versionian/component_types/base"
    autoload :Integer, "versionian/component_types/integer"
    autoload :Float, "versionian/component_types/float"
    autoload :Enum, "versionian/component_types/enum"
    autoload :String, "versionian/component_types/string"
    autoload :DatePart, "versionian/component_types/date_part"
    autoload :Prerelease, "versionian/component_types/prerelease"
    autoload :Postfix, "versionian/component_types/postfix"
    autoload :Hash, "versionian/component_types/hash"

    @types = {}
    @mutex = Mutex.new

    class << self
      def register(name, type_class)
        @mutex.synchronize do
          @types[name] = type_class
        end
      end

      def resolve(type)
        @types[type] || raise(Errors::InvalidSchemeError, "Unknown component type: #{type}")
      end

      def registered
        @types.keys
      end
    end
  end
end

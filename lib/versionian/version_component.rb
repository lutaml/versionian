# frozen_string_literal: true

module Versionian
  class VersionComponent
    attr_reader :name, :type, :value, :weight, :values, :order, :definition

    def initialize(name:, type:, value:, weight: 1, values: [], order: [], definition: nil)
      @name = name
      @type = type
      @value = value
      @weight = weight
      @values = values
      @order = order
      @definition = definition
      freeze
    end

    def to_comparable
      type_class = ComponentTypes.resolve(@type)
      type_class.to_comparable(@value, self)
    end

    def to_s
      type_class = ComponentTypes.resolve(@type)
      type_class.format(@value)
    end
  end
end

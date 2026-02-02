# frozen_string_literal: true

RSpec.describe Versionian::ComponentTypes::Integer do
  describe ".parse" do
    it "parses integer values" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "integer")
      expect(described_class.parse("42", definition)).to eq(42)
    end

    it "returns default for nil" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "integer", default: "0")
      expect(described_class.parse(nil, definition)).to eq(0)
    end

    it "raises error for invalid input" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "integer")
      expect { described_class.parse("abc", definition) }.to raise_error(Versionian::Errors::ParseError)
    end
  end

  describe ".to_comparable" do
    it "returns the value" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "integer")
      expect(described_class.to_comparable(42, definition)).to eq(42)
    end
  end

  describe ".format" do
    it "formats as string" do
      expect(described_class.format(42)).to eq("42")
    end
  end
end

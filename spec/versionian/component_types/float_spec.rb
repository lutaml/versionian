# frozen_string_literal: true

RSpec.describe Versionian::ComponentTypes::Float do
  describe ".parse" do
    it "parses float values" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "float")
      expect(described_class.parse("3.14", definition)).to eq(3.14)
    end

    it "returns default for nil" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "float", default: "0.0")
      expect(described_class.parse(nil, definition)).to eq(0.0)
    end

    it "raises error for invalid input" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "float")
      expect { described_class.parse("abc", definition) }.to raise_error(Versionian::Errors::ParseError)
    end
  end

  describe ".to_comparable" do
    it "returns the value" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "float")
      expect(described_class.to_comparable(3.14, definition)).to eq(3.14)
    end
  end

  describe ".format" do
    it "formats as string" do
      expect(described_class.format(3.14)).to eq("3.14")
    end
  end
end

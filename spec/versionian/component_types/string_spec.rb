# frozen_string_literal: true

RSpec.describe Versionian::ComponentTypes::String do
  describe ".parse" do
    it "parses string values" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "string")
      expect(described_class.parse("hello", definition)).to eq("hello")
    end

    it "returns default for nil" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "string", default: "default")
      expect(described_class.parse(nil, definition)).to eq("default")
    end

    it "returns empty string when no default" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "string")
      expect(described_class.parse(nil, definition)).to eq("")
    end
  end

  describe ".to_comparable" do
    it "returns the value" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "string")
      expect(described_class.to_comparable("hello", definition)).to eq("hello")
    end
  end

  describe ".format" do
    it "returns the value" do
      expect(described_class.format("hello")).to eq("hello")
    end
  end
end

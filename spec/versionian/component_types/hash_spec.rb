# frozen_string_literal: true

RSpec.describe Versionian::ComponentTypes::Hash do
  let(:definition) { Versionian::ComponentDefinition.new(name: "hash", type: "hash") }

  describe ".parse" do
    it "parses hash values" do
      expect(described_class.parse("ABC123", definition)).to eq("abc123")
      expect(described_class.parse("def456", definition)).to eq("def456")
    end

    it "normalizes to lowercase" do
      expect(described_class.parse("ABCDEF", definition)).to eq("abcdef")
      expect(described_class.parse("AbCdEf", definition)).to eq("abcdef")
    end

    it "returns default for nil" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "hash", default: "default")
      expect(described_class.parse(nil, definition)).to eq("default")
    end
  end

  describe ".to_comparable" do
    it "returns array of length and value" do
      expect(described_class.to_comparable("abc", definition)).to eq([3, "abc"])
      expect(described_class.to_comparable("abcd", definition)).to eq([4, "abcd"])
    end
  end

  describe ".format" do
    it "returns the value" do
      expect(described_class.format("abc123")).to eq("abc123")
    end
  end
end

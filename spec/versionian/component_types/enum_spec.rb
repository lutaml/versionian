# frozen_string_literal: true

RSpec.describe Versionian::ComponentTypes::Enum do
  let(:definition) do
    Versionian::ComponentDefinition.new(
      name: "stage",
      type: "enum",
      values: %i[alpha beta rc stable],
      order: %i[alpha beta rc stable]
    )
  end

  describe ".parse" do
    it "parses enum values" do
      expect(described_class.parse("alpha", definition)).to eq(:alpha)
      expect(described_class.parse("beta", definition)).to eq(:beta)
    end

    it "returns nil for nil" do
      expect(described_class.parse(nil, definition)).to be_nil
    end

    it "raises error for invalid value" do
      expect { described_class.parse("invalid", definition) }.to raise_error(Versionian::Errors::ParseError)
    end

    it "accepts any value when values list is empty" do
      empty_def = Versionian::ComponentDefinition.new(name: "test", type: "enum")
      expect(described_class.parse("custom", empty_def)).to eq(:custom)
    end
  end

  describe ".to_comparable" do
    it "returns the order index" do
      expect(described_class.to_comparable(:alpha, definition)).to eq(0)
      expect(described_class.to_comparable(:beta, definition)).to eq(1)
      expect(described_class.to_comparable(:rc, definition)).to eq(2)
    end

    it "returns infinity for nil" do
      expect(described_class.to_comparable(nil, definition)).to eq(Float::INFINITY)
    end
  end

  describe ".format" do
    it "formats as string" do
      expect(described_class.format(:alpha)).to eq("alpha")
    end

    it "returns empty string for nil" do
      expect(described_class.format(nil)).to eq("")
    end
  end
end

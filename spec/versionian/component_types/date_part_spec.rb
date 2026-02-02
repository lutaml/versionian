# frozen_string_literal: true

RSpec.describe Versionian::ComponentTypes::DatePart do
  describe ".parse" do
    it "parses year values" do
      definition = Versionian::ComponentDefinition.new(name: "year", type: "date_part", subtype: "year")
      expect(described_class.parse("2024", definition)).to eq(2024)
    end

    it "parses month values" do
      definition = Versionian::ComponentDefinition.new(name: "month", type: "date_part", subtype: "month")
      expect(described_class.parse("01", definition)).to eq(1)
      expect(described_class.parse("12", definition)).to eq(12)
    end

    it "parses day values" do
      definition = Versionian::ComponentDefinition.new(name: "day", type: "date_part", subtype: "day")
      expect(described_class.parse("01", definition)).to eq(1)
      expect(described_class.parse("31", definition)).to eq(31)
    end

    it "validates month range" do
      definition = Versionian::ComponentDefinition.new(name: "month", type: "date_part", subtype: "month")
      expect { described_class.parse("00", definition) }.to raise_error(Versionian::Errors::ParseError)
      expect { described_class.parse("13", definition) }.to raise_error(Versionian::Errors::ParseError)
    end

    it "validates day range" do
      definition = Versionian::ComponentDefinition.new(name: "day", type: "date_part", subtype: "day")
      expect { described_class.parse("00", definition) }.to raise_error(Versionian::Errors::ParseError)
      expect { described_class.parse("32", definition) }.to raise_error(Versionian::Errors::ParseError)
    end

    it "returns default for nil" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "date_part", default: "1")
      expect(described_class.parse(nil, definition)).to eq(1)
    end
  end

  describe ".to_comparable" do
    it "returns the value" do
      definition = Versionian::ComponentDefinition.new(name: "test", type: "date_part")
      expect(described_class.to_comparable(2024, definition)).to eq(2024)
    end
  end

  describe ".format" do
    it "pads single digits" do
      expect(described_class.format(1)).to eq("01")
      expect(described_class.format(9)).to eq("09")
    end

    it "does not pad double digits" do
      expect(described_class.format(10)).to eq("10")
      expect(described_class.format(2024)).to eq("2024")
    end
  end
end

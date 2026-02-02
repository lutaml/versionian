# frozen_string_literal: true

RSpec.describe Versionian::Schemes::Declarative do
  describe "#initialize" do
    it "creates a scheme with name and component definitions" do
      segments = [
        Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :minor, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :patch, type: :integer)
      ]

      scheme = described_class.new(name: :semantic_like, component_definitions: segments)

      expect(scheme.name).to eq(:semantic_like)
      expect(scheme.component_definitions).to eq(segments)
    end

    it "accepts optional description" do
      segments = [
        Versionian::ComponentDefinition.new(name: :major, type: :integer)
      ]

      scheme = described_class.new(
        name: :simple,
        component_definitions: segments,
        description: "Simple version scheme"
      )

      expect(scheme.description).to eq("Simple version scheme")
    end
  end

  describe "#parse" do
    context "semantic versioning scheme" do
      let(:segments) do
        [
          Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
          Versionian::ComponentDefinition.new(name: :minor, type: :integer, separator: "."),
          Versionian::ComponentDefinition.new(name: :patch, type: :integer),
          Versionian::ComponentDefinition.new(name: :prerelease, type: :prerelease, prefix: "-", optional: true),
          Versionian::ComponentDefinition.new(name: :build, type: :string, prefix: "+", optional: true)
        ]
      end
      let(:scheme) { described_class.new(name: :semantic, component_definitions: segments) }

      it "parses simple version" do
        version = scheme.parse("1.2.3")

        expect(version.raw_string).to eq("1.2.3")
        expect(version.scheme).to eq(scheme)
      end

      it "parses version with prerelease" do
        version = scheme.parse("1.2.3-alpha.1")

        expect(version.raw_string).to eq("1.2.3-alpha.1")
      end

      it "parses version with build metadata" do
        version = scheme.parse("1.2.3+build.123")

        expect(version.raw_string).to eq("1.2.3+build.123")
      end

      it "raises error for invalid version" do
        expect { scheme.parse("invalid") }.to raise_error(Versionian::Errors::ParseError)
      end
    end

    context "calver scheme" do
      let(:segments) do
        [
          Versionian::ComponentDefinition.new(name: :year, type: :date_part, subtype: :year, separator: "."),
          Versionian::ComponentDefinition.new(name: :month, type: :date_part, subtype: :month, separator: "."),
          Versionian::ComponentDefinition.new(name: :day, type: :date_part, subtype: :day)
        ]
      end
      let(:scheme) { described_class.new(name: :calver, component_definitions: segments) }

      it "parses YYYY.MM.DD format" do
        version = scheme.parse("2024.01.17")

        expect(version.raw_string).to eq("2024.01.17")
      end

      it "raises error for invalid month" do
        expect { scheme.parse("2024.13.17") }.to raise_error(Versionian::Errors::ParseError)
      end
    end
  end

  describe "#valid?" do
    let(:segments) do
      [
        Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :minor, type: :integer)
      ]
    end
    let(:scheme) { described_class.new(name: :simple, component_definitions: segments) }

    it "returns true for valid version" do
      expect(scheme.valid?("1.2")).to be true
    end

    it "returns false for invalid version" do
      expect(scheme.valid?("1")).to be false
    end

    it "returns false for non-matching format" do
      expect(scheme.valid?("abc")).to be false
    end
  end

  describe "#supports?" do
    let(:segments) do
      [
        Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :minor, type: :integer)
      ]
    end
    let(:scheme) { described_class.new(name: :simple, component_definitions: segments) }

    it "returns true for supported version" do
      expect(scheme.supports?("1.2")).to be true
    end

    it "returns false for unsupported version" do
      expect(scheme.supports?("1.2.3")).to be false
    end
  end

  describe "#compare" do
    let(:segments) do
      [
        Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :minor, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :patch, type: :integer)
      ]
    end
    let(:scheme) { described_class.new(name: :semantic_like, component_definitions: segments) }

    it "compares versions correctly" do
      expect(scheme.compare("1.2.3", "1.2.4")).to eq(-1)
      expect(scheme.compare("1.2.3", "1.2.3")).to eq(0)
      expect(scheme.compare("1.2.4", "1.2.3")).to eq(1)
    end

    it "compares versions with different major versions" do
      expect(scheme.compare("1.2.3", "2.0.0")).to eq(-1)
    end
  end

  describe "#render" do
    let(:segments) do
      [
        Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :minor, type: :integer)
      ]
    end
    let(:scheme) { described_class.new(name: :simple, component_definitions: segments) }

    it "renders version back to string" do
      version = scheme.parse("1.2")
      expect(scheme.render(version)).to eq("1.2")
    end
  end
end

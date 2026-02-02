# frozen_string_literal: true

RSpec.describe Versionian::Parsers::Declarative do
  describe "#initialize" do
    it "creates parser with segment definitions" do
      segments = [
        Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :minor, type: :integer),
        Versionian::ComponentDefinition.new(name: :patch, type: :integer)
      ]

      parser = described_class.new(segments)

      expect(parser.segment_definitions).to eq(segments)
    end

    it "raises error for segment without name" do
      segments = [
        Versionian::ComponentDefinition.new(name: nil, type: :integer)
      ]

      expect { described_class.new(segments) }.to raise_error(
        Versionian::Errors::InvalidSchemeError, "segment name required"
      )
    end

    it "raises error for segment without type" do
      segments = [
        Versionian::ComponentDefinition.new(name: :major, type: nil)
      ]

      expect { described_class.new(segments) }.to raise_error(
        Versionian::Errors::InvalidSchemeError, "segment type required"
      )
    end

    it "raises error for optional segment without prefix or separator" do
      segments = [
        Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :extra, type: :integer, optional: true)
      ]

      expect { described_class.new(segments) }.to raise_error(
        Versionian::Errors::InvalidSchemeError,
        "Optional segment 'extra' must have prefix or separator"
      )
    end
  end

  describe "#parse" do
    context "simple integer sequence" do
      let(:segments) do
        [
          Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
          Versionian::ComponentDefinition.new(name: :minor, type: :integer, separator: "."),
          Versionian::ComponentDefinition.new(name: :patch, type: :integer)
        ]
      end
      let(:parser) { described_class.new(segments) }

      it "parses 1.2.3" do
        result = parser.parse("1.2.3")

        expect(result[:major]).to eq(1)
        expect(result[:minor]).to eq(2)
        expect(result[:patch]).to eq(3)
      end

      it "parses 10.20.30" do
        result = parser.parse("10.20.30")

        expect(result[:major]).to eq(10)
        expect(result[:minor]).to eq(20)
        expect(result[:patch]).to eq(30)
      end

      it "raises error for invalid format" do
        expect { parser.parse("1.2") }.to raise_error(
          Versionian::Errors::ParseError
        )
      end

      it "raises error for non-numeric input" do
        expect { parser.parse("a.b.c") }.to raise_error(
          Versionian::Errors::ParseError
        )
      end
    end

    context "optional segments" do
      let(:segments) do
        [
          Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
          Versionian::ComponentDefinition.new(name: :minor, type: :integer),
          Versionian::ComponentDefinition.new(name: :prerelease, type: :string, prefix: "-", optional: true)
        ]
      end
      let(:parser) { described_class.new(segments) }

      it "parses version without optional segment" do
        result = parser.parse("1.2")

        expect(result[:major]).to eq(1)
        expect(result[:minor]).to eq(2)
        expect(result[:prerelease]).to be_nil
      end

      it "parses version with optional segment" do
        result = parser.parse("1.2-alpha")

        expect(result[:major]).to eq(1)
        expect(result[:minor]).to eq(2)
        expect(result[:prerelease]).to eq("alpha")
      end

      it "parses version with more complex prerelease" do
        result = parser.parse("1.2-alpha.1")

        expect(result[:major]).to eq(1)
        expect(result[:minor]).to eq(2)
        expect(result[:prerelease]).to eq("alpha.1")
      end
    end

    context "enum segment" do
      let(:segments) do
        [
          Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
          Versionian::ComponentDefinition.new(name: :minor, type: :integer, separator: "."),
          Versionian::ComponentDefinition.new(name: :stage, type: :enum, prefix: "-", optional: true,
                                              values: [:alpha, :beta, :rc, :stable],
                                              order: [:alpha, :beta, :rc, :stable])
        ]
      end
      let(:parser) { described_class.new(segments) }

      it "parses version with enum stage" do
        result = parser.parse("1.2-beta")

        expect(result[:major]).to eq(1)
        expect(result[:minor]).to eq(2)
        expect(result[:stage]).to eq(:beta)
      end

      it "raises error for invalid enum value" do
        expect { parser.parse("1.2-gamma") }.to raise_error(
          Versionian::Errors::ParseError
        )
      end
    end

    context "date part segment" do
      let(:segments) do
        [
          Versionian::ComponentDefinition.new(name: :year, type: :date_part, subtype: :year, separator: "."),
          Versionian::ComponentDefinition.new(name: :month, type: :date_part, subtype: :month, separator: "."),
          Versionian::ComponentDefinition.new(name: :day, type: :date_part, subtype: :day)
        ]
      end
      let(:parser) { described_class.new(segments) }

      it "parses YYYY.MM.DD format" do
        result = parser.parse("2024.01.17")

        expect(result[:year]).to eq(2024)
        expect(result[:month]).to eq(1)
        expect(result[:day]).to eq(17)
      end

      it "raises error for invalid month" do
        expect { parser.parse("2024.13.17") }.to raise_error(
          Versionian::Errors::ParseError
        )
      end

      it "raises error for invalid day" do
        expect { parser.parse("2024.01.32") }.to raise_error(
          Versionian::Errors::ParseError
        )
      end
    end

    context "semantic versioning" do
      let(:segments) do
        [
          Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
          Versionian::ComponentDefinition.new(name: :minor, type: :integer, separator: "."),
          Versionian::ComponentDefinition.new(name: :patch, type: :integer),
          Versionian::ComponentDefinition.new(name: :prerelease, type: :prerelease, prefix: "-", optional: true),
          Versionian::ComponentDefinition.new(name: :build, type: :string, prefix: "+", optional: true)
        ]
      end
      let(:parser) { described_class.new(segments) }

      it "parses simple version" do
        result = parser.parse("1.2.3")

        expect(result[:major]).to eq(1)
        expect(result[:minor]).to eq(2)
        expect(result[:patch]).to eq(3)
        expect(result[:prerelease]).to be_nil
        expect(result[:build]).to be_nil
      end

      it "parses version with prerelease" do
        result = parser.parse("1.2.3-alpha.1")

        expect(result[:major]).to eq(1)
        expect(result[:minor]).to eq(2)
        expect(result[:patch]).to eq(3)
        expect(result[:prerelease]).to eq([:alpha, 1])
        expect(result[:build]).to be_nil
      end

      it "parses version with build metadata" do
        result = parser.parse("1.2.3+build.123")

        expect(result[:major]).to eq(1)
        expect(result[:minor]).to eq(2)
        expect(result[:patch]).to eq(3)
        expect(result[:prerelease]).to be_nil
        expect(result[:build]).to eq("build.123")
      end

      it "parses version with both prerelease and build" do
        result = parser.parse("1.2.3-alpha.1+build.123")

        expect(result[:major]).to eq(1)
        expect(result[:minor]).to eq(2)
        expect(result[:patch]).to eq(3)
        expect(result[:prerelease]).to eq([:alpha, 1])
        expect(result[:build]).to eq("build.123")
      end
    end

    context "hash segment" do
      let(:segments) do
        [
          Versionian::ComponentDefinition.new(name: :year, type: :date_part, subtype: :year, separator: "."),
          Versionian::ComponentDefinition.new(name: :month, type: :date_part, subtype: :month, separator: "."),
          Versionian::ComponentDefinition.new(name: :hash, type: :hash)
        ]
      end
      let(:parser) { described_class.new(segments) }

      it "parses hashver format" do
        result = parser.parse("2024.01.abc123")

        expect(result[:year]).to eq(2024)
        expect(result[:month]).to eq(1)
        expect(result[:hash]).to eq("abc123")
      end
    end

    context "postfix segment (solover)" do
      let(:segments) do
        [
          Versionian::ComponentDefinition.new(name: :number, type: :integer),
          # Postfix component type handles the prefix internally (+ or -)
          # The prefix here is just to indicate the segment comes after the number
          # include_prefix_in_value ensures the prefix is passed to the component type
          Versionian::ComponentDefinition.new(name: :postfix, type: :postfix, optional: true, prefix: "+",
                                              include_prefix_in_value: true)
        ]
      end
      let(:parser) { described_class.new(segments) }

      it "parses version without postfix" do
        # For SoloVer without postfix, the entire string is just the number
        # The postfix segment is optional but has prefix "+", so it's not present
        result = parser.parse("5")

        expect(result[:number]).to eq(5)
        expect(result[:postfix]).to be_nil
      end

      it "parses version with + postfix" do
        # Postfix component type handles the + internally
        result = parser.parse("5+hotfix")

        expect(result[:number]).to eq(5)
        # Postfix type stores the prefix as part of the value
        expect(result[:postfix]).to eq({ prefix: "+", identifier: "hotfix" })
      end

      it "parses version with - postfix" do
        # SoloVer with beta postfix
        result = parser.parse("5-beta")

        expect(result[:number]).to eq(5)
        expect(result[:postfix]).to eq({ prefix: "-", identifier: "beta" })
      end
    end

    context "empty string" do
      it "raises error for empty string" do
        segments = [
          Versionian::ComponentDefinition.new(name: :major, type: :integer)
        ]
        parser = described_class.new(segments)

        expect { parser.parse("") }.to raise_error(
          Versionian::Errors::ParseError
        )
      end
    end
  end

  describe "#match?" do
    let(:segments) do
      [
        Versionian::ComponentDefinition.new(name: :major, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :minor, type: :integer, separator: "."),
        Versionian::ComponentDefinition.new(name: :patch, type: :integer)
      ]
    end
    let(:parser) { described_class.new(segments) }

    it "returns true for matching string" do
      expect(parser.match?("1.2.3")).to be true
    end

    it "returns false for non-matching string" do
      expect(parser.match?("1.2")).to be false
    end

    it "returns false for invalid format" do
      expect(parser.match?("abc")).to be false
    end
  end
end

# frozen_string_literal: true

RSpec.describe Versionian::ComponentDefinition do
  describe "#initialize" do
    it "creates a definition with basic attributes" do
      defn = described_class.new(
        name: :major,
        type: :integer
      )

      expect(defn.name).to eq(:major)
      expect(defn.type).to eq(:integer)
    end

    it "sets default values" do
      defn = described_class.new(
        name: :major,
        type: :integer
      )

      expect(defn.values).to eq([])
      expect(defn.order).to eq([])
      expect(defn.weight).to eq(1)
      expect(defn.optional).to be false
      expect(defn.ignore_in_comparison).to be false
      expect(defn.min_count).to eq(1)
      expect(defn.max_count).to eq(1)
      expect(defn.validate).to eq({})
    end

    it "accepts enum values" do
      defn = described_class.new(
        name: :stage,
        type: :enum,
        values: %i[alpha beta rc],
        order: %i[alpha beta rc]
      )

      expect(defn.values).to eq(%i[alpha beta rc])
      expect(defn.order).to eq(%i[alpha beta rc])
    end

    it "accepts optional flag" do
      defn = described_class.new(
        name: :prerelease,
        type: :prerelease,
        optional: true
      )

      expect(defn.optional).to be true
    end

    it "accepts default value" do
      defn = described_class.new(
        name: :patch,
        type: :integer,
        default: 0
      )

      expect(defn.default).to eq(0)
    end
  end

  describe ".from_hash" do
    it "creates definition from hash with string keys" do
      hash = {
        "name" => "major",
        "type" => "integer",
        "separator" => "."
      }

      defn = described_class.from_hash(hash)

      expect(defn.name).to eq(:major)
      expect(defn.type).to eq(:integer)
      expect(defn.separator).to eq(".")
    end

    it "converts values to symbols" do
      hash = {
        "name" => "stage",
        "type" => "enum",
        "values" => %w[alpha beta],
        "order" => %w[alpha beta]
      }

      defn = described_class.from_hash(hash)

      expect(defn.name).to eq(:stage)
      expect(defn.type).to eq(:enum)
      expect(defn.values).to eq(%i[alpha beta])
      expect(defn.order).to eq(%i[alpha beta])
    end

    it "handles nil values" do
      hash = {
        "name" => "major",
        "type" => "integer"
      }

      defn = described_class.from_hash(hash)

      expect(defn.subtype).to be_nil
      expect(defn.separator).to be_nil
      expect(defn.prefix).to be_nil
      expect(defn.suffix).to be_nil
    end

    it "accepts symbol keys directly" do
      hash = {
        name: :major,
        type: :integer,
        separator: "."
      }

      defn = described_class.from_hash(hash)

      expect(defn.name).to eq(:major)
      expect(defn.type).to eq(:integer)
      expect(defn.separator).to eq(".")
    end
  end

  describe "#validate!" do
    it "passes with valid definition" do
      defn = described_class.new(
        name: :major,
        type: :integer
      )

      expect { defn.validate! }.not_to raise_error
    end

    it "raises error when name is nil" do
      defn = described_class.new(
        name: nil,
        type: :integer
      )

      expect { defn.validate! }.to raise_error(Versionian::Errors::InvalidSchemeError, "name is required")
    end

    it "raises error when type is nil" do
      defn = described_class.new(
        name: :major,
        type: nil
      )

      expect { defn.validate! }.to raise_error(Versionian::Errors::InvalidSchemeError, "type is required")
    end
  end

  describe "#has_separator?" do
    it "returns true when separator is present" do
      defn = described_class.new(
        name: :major,
        type: :integer,
        separator: "."
      )

      expect(defn.has_separator?).to be true
    end

    it "returns false when separator is nil" do
      defn = described_class.new(
        name: :major,
        type: :integer
      )

      expect(defn.has_separator?).to be false
    end

    it "returns false when separator is empty string" do
      defn = described_class.new(
        name: :major,
        type: :integer,
        separator: ""
      )

      expect(defn.has_separator?).to be false
    end
  end

  describe "#has_prefix?" do
    it "returns true when prefix is present" do
      defn = described_class.new(
        name: :prerelease,
        type: :prerelease,
        prefix: "-"
      )

      expect(defn.has_prefix?).to be true
    end

    it "returns false when prefix is nil" do
      defn = described_class.new(
        name: :major,
        type: :integer
      )

      expect(defn.has_prefix?).to be false
    end

    it "returns false when prefix is empty string" do
      defn = described_class.new(
        name: :major,
        type: :integer,
        prefix: ""
      )

      expect(defn.has_prefix?).to be false
    end
  end

  describe "#has_suffix?" do
    it "returns true when suffix is present" do
      defn = described_class.new(
        name: :major,
        type: :integer,
        suffix: "x"
      )

      expect(defn.has_suffix?).to be true
    end

    it "returns false when suffix is nil" do
      defn = described_class.new(
        name: :major,
        type: :integer
      )

      expect(defn.has_suffix?).to be false
    end
  end

  describe "segment attributes" do
    it "accepts separator" do
      defn = described_class.new(
        name: :major,
        type: :integer,
        separator: "."
      )

      expect(defn.separator).to eq(".")
    end

    it "accepts prefix" do
      defn = described_class.new(
        name: :prerelease,
        type: :prerelease,
        prefix: "-"
      )

      expect(defn.prefix).to eq("-")
    end

    it "accepts suffix" do
      defn = described_class.new(
        name: :major,
        type: :integer,
        suffix: "."
      )

      expect(defn.suffix).to eq(".")
    end

    it "accepts min_count and max_count" do
      defn = described_class.new(
        name: :parts,
        type: :integer,
        min_count: 1,
        max_count: 5
      )

      expect(defn.min_count).to eq(1)
      expect(defn.max_count).to eq(5)
    end

    it "accepts validate hash" do
      defn = described_class.new(
        name: :year,
        type: :integer,
        validate: { min: 2000, max: 9999 }
      )

      expect(defn.validate).to eq({ min: 2000, max: 9999 })
    end
  end
end

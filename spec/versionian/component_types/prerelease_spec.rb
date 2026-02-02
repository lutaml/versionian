# frozen_string_literal: true

RSpec.describe Versionian::ComponentTypes::Prerelease do
  let(:definition) { Versionian::ComponentDefinition.new(name: "prerelease", type: "prerelease") }

  describe ".parse" do
    it "parses prerelease identifiers" do
      expect(described_class.parse("alpha", definition)).to eq([:alpha])
      expect(described_class.parse("alpha.1", definition)).to eq([:alpha, 1])
      expect(described_class.parse("beta.2", definition)).to eq([:beta, 2])
    end

    it "returns nil for empty" do
      expect(described_class.parse(nil, definition)).to be_nil
      expect(described_class.parse("", definition)).to be_nil
    end
  end

  describe ".to_comparable" do
    it "returns the array" do
      expect(described_class.to_comparable([:alpha, 1], definition)).to eq([:alpha, 1])
    end

    it "returns [1] for nil" do
      expect(described_class.to_comparable(nil, definition)).to eq([1])
    end
  end

  describe ".format" do
    it "formats prerelease array" do
      expect(described_class.format([:alpha, 1])).to eq("alpha.1")
      expect(described_class.format([:beta])).to eq("beta")
    end

    it "returns empty string for nil" do
      expect(described_class.format(nil)).to eq("")
    end
  end

  describe ".compare_prerelease_arrays" do
    it "compares according to SemVer rules" do
      a = [:alpha, 1]
      b = [:alpha, 2]
      c = [:beta, 1]
      d = [:beta, 1, :hotfix]

      expect(described_class.compare_prerelease_arrays(a, b)).to eq(-1)
      expect(described_class.compare_prerelease_arrays(b, a)).to eq(1)
      expect(described_class.compare_prerelease_arrays(a, a)).to eq(0)
      expect(described_class.compare_prerelease_arrays(a, c)).to eq(-1)
      expect(described_class.compare_prerelease_arrays(c, a)).to eq(1)
      expect(described_class.compare_prerelease_arrays(c, d)).to eq(-1)
    end

    it "treats nil as highest priority" do
      expect(described_class.compare_prerelease_arrays(nil, [:alpha, 1])).to eq(1)
      expect(described_class.compare_prerelease_arrays([:alpha, 1], nil)).to eq(-1)
      expect(described_class.compare_prerelease_arrays(nil, nil)).to eq(0)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Versionian::VersionIdentifier do
  let(:scheme) { Versionian::Schemes::Semantic.new }
  let(:version) do
    described_class.new(
      raw_string: "1.2.3",
      scheme: scheme,
      components: [],
      comparable_array: [Gem::Version.new("1.2.3")]
    )
  end

  describe "#initialize" do
    it "creates a version with attributes" do
      expect(version.raw_string).to eq("1.2.3")
      expect(version.scheme).to eq(scheme)
    end

    it "freezes the version" do
      expect(version).to be_frozen
    end
  end

  describe "#<=>" do
    let(:v1) { scheme.parse("1.2.3") }
    let(:v2) { scheme.parse("1.2.4") }
    let(:v3) { scheme.parse("1.2.3") }

    it "compares versions correctly" do
      expect(v1 <=> v2).to eq(-1)
      expect(v2 <=> v1).to eq(1)
      expect(v1 <=> v3).to eq(0)
    end

    it "raises error when comparing different schemes" do
      other_scheme = Versionian::Schemes::CalVer.new
      other_version = other_scheme.parse("2024.01.01")

      expect { version <=> other_version }.to raise_error(ArgumentError)
    end
  end

  describe "#component" do
    it "returns nil for non-existent component" do
      expect(version.component(:nonexistent)).to be_nil
    end
  end

  describe "#to_s" do
    it "returns the raw string" do
      expect(version.to_s).to eq("1.2.3")
    end
  end

  describe "#inspect" do
    it "returns a useful inspect string" do
      expect(version.inspect).to include("1.2.3")
      expect(version.inspect).to include("semantic")
    end
  end
end

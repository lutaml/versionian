# frozen_string_literal: true

RSpec.describe Versionian::Schemes::Semantic do
  let(:scheme) { described_class.new }

  describe "#parse" do
    it "parses semantic versions" do
      version = scheme.parse("1.2.3")
      expect(version.raw_string).to eq("1.2.3")
      expect(version.scheme).to eq(scheme)
    end

    it "parses versions with prerelease" do
      version = scheme.parse("1.2.3-alpha")
      expect(version.raw_string).to eq("1.2.3-alpha")
    end

    it "parses versions with build metadata" do
      version = scheme.parse("1.2.3+build")
      expect(version.raw_string).to eq("1.2.3+build")
    end

    it "raises error for empty string" do
      expect { scheme.parse("") }.to raise_error(Versionian::Errors::InvalidVersionError)
    end

    it "raises error for nil" do
      expect { scheme.parse(nil) }.to raise_error(Versionian::Errors::InvalidVersionError)
    end
  end

  describe "#compare" do
    it "compares versions correctly" do
      expect(scheme.compare("1.2.3", "1.2.4")).to eq(-1)
      expect(scheme.compare("1.2.4", "1.2.3")).to eq(1)
      expect(scheme.compare("1.2.3", "1.2.3")).to eq(0)
    end

    it "compares prerelease versions" do
      expect(scheme.compare("1.0.0-alpha", "1.0.0-beta")).to eq(-1)
      expect(scheme.compare("1.0.0-alpha.1", "1.0.0-alpha")).to eq(1)
    end
  end

  describe "#valid?" do
    it "returns true for valid versions" do
      expect(scheme.valid?("1.2.3")).to be true
      expect(scheme.valid?("1.0.0-alpha")).to be true
    end

    it "returns false for invalid versions" do
      expect(scheme.valid?("invalid")).to be false
      expect(scheme.valid?("")).to be false
    end
  end

  describe "#supports?" do
    it "returns true for valid versions" do
      expect(scheme.supports?("1.2.3")).to be true
      expect(scheme.supports?("1.0.0-alpha")).to be true
    end

    it "returns false for invalid versions" do
      expect(scheme.supports?("invalid")).to be false
      expect(scheme.supports?("")).to be false
    end
  end

  describe "#matches_range?" do
    it "matches equals range" do
      range = Versionian::VersionRange.new(:equals, scheme, version: "1.2.3")
      expect(scheme.matches_range?("1.2.3", range)).to be true
      expect(scheme.matches_range?("1.2.4", range)).to be false
    end

    it "matches after range" do
      range = Versionian::VersionRange.new(:after, scheme, version: "1.2.0")
      expect(scheme.matches_range?("1.2.3", range)).to be true
      expect(scheme.matches_range?("1.1.9", range)).to be false
    end

    it "matches between range" do
      range = Versionian::VersionRange.new(:between, scheme, from: "1.0.0", to: "2.0.0")
      expect(scheme.matches_range?("1.5.0", range)).to be true
      expect(scheme.matches_range?("2.1.0", range)).to be false
    end
  end

  describe "#==" do
    it "compares schemes by name" do
      scheme1 = described_class.new(name: :semantic)
      scheme2 = described_class.new(name: :semantic)
      scheme3 = described_class.new(name: :other)

      expect(scheme1).to eq(scheme2)
      expect(scheme1).not_to eq(scheme3)
    end
  end
end

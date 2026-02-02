# frozen_string_literal: true

RSpec.describe Versionian::Schemes::SoloVer do
  let(:scheme) { described_class.new }

  describe "#parse" do
    it "parses simple SoloVer versions" do
      version = scheme.parse("42")
      expect(version.raw_string).to eq("42")
      expect(version.component(:number).value).to eq(42)
    end

    it "parses SoloVer with +hotfix postfix" do
      version = scheme.parse("42+hotfix")
      expect(version.raw_string).to eq("42+hotfix")
      expect(version.component(:number).value).to eq(42)
      expect(version.component(:postfix).value).to eq({ prefix: "+", identifier: "hotfix" })
    end

    it "parses SoloVer with -beta postfix" do
      version = scheme.parse("42-beta")
      expect(version.raw_string).to eq("42-beta")
      expect(version.component(:number).value).to eq(42)
      expect(version.component(:postfix).value).to eq({ prefix: "-", identifier: "beta" })
    end

    it "parses SoloVer with numeric postfix" do
      version = scheme.parse("100+123")
      expect(version.raw_string).to eq("100+123")
      expect(version.component(:number).value).to eq(100)
      expect(version.component(:postfix).value).to eq({ prefix: "+", identifier: "123" })
    end

    it "raises error for empty string" do
      expect { scheme.parse("") }.to raise_error(Versionian::Errors::InvalidVersionError)
    end

    it "raises error for nil" do
      expect { scheme.parse(nil) }.to raise_error(Versionian::Errors::InvalidVersionError)
    end

    it "raises error for invalid format" do
      expect { scheme.parse("1.2.3") }.to raise_error(Versionian::Errors::ParseError)
    end
  end

  describe "#compare" do
    it "compares simple versions correctly" do
      expect(scheme.compare("1", "2")).to eq(-1)
      expect(scheme.compare("2", "1")).to eq(1)
      expect(scheme.compare("42", "42")).to eq(0)
    end

    it "compares versions with postfixes" do
      expect(scheme.compare("1", "1+hotfix")).to eq(-1) # No postfix < +postfix
      expect(scheme.compare("1+hotfix", "1")).to eq(1)
      expect(scheme.compare("1+hotfix", "1+hotfix")).to eq(0)
    end

    it "compares versions with different postfixes" do
      expect(scheme.compare("1+alpha", "1+beta")).to eq(-1) # alpha < beta lexicographically
      expect(scheme.compare("1+beta", "1+alpha")).to eq(1)
    end

    it "compares versions with - (before) postfix" do
      expect(scheme.compare("1", "1-beta")).to eq(-1) # No postfix < -postfix
      expect(scheme.compare("1+hotfix", "1-beta")).to eq(-1) # + < -
      expect(scheme.compare("1-beta", "1+hotfix")).to eq(1)
    end
  end

  describe "#valid?" do
    it "returns true for valid SoloVer versions" do
      expect(scheme.valid?("1")).to be true
      expect(scheme.valid?("42")).to be true
      expect(scheme.valid?("100+hotfix")).to be true
      expect(scheme.valid?("1-beta")).to be true
    end

    it "returns false for invalid versions" do
      expect(scheme.valid?("")).to be false
      expect(scheme.valid?("1.2.3")).to be false
      expect(scheme.valid?("invalid")).to be false
    end
  end

  describe "#matches_range?" do
    it "matches equals range" do
      range = Versionian::VersionRange.new(:equals, scheme, version: "42")
      expect(scheme.matches_range?("42", range)).to be true
      expect(scheme.matches_range?("43", range)).to be false
    end

    it "matches after range" do
      range = Versionian::VersionRange.new(:after, scheme, version: "10")
      expect(scheme.matches_range?("15", range)).to be true
      expect(scheme.matches_range?("5", range)).to be false
    end

    it "matches between range" do
      range = Versionian::VersionRange.new(:between, scheme, from: "10", to: "20")
      expect(scheme.matches_range?("15", range)).to be true
      expect(scheme.matches_range?("25", range)).to be false
    end
  end

  describe "#render" do
    it "renders simple version" do
      version = scheme.parse("42")
      expect(version.to_s).to eq("42")
    end

    it "renders version with postfix" do
      version = scheme.parse("42+hotfix")
      expect(version.to_s).to eq("42+hotfix")
    end
  end
end

# frozen_string_literal: true

RSpec.describe Versionian::Schemes::WendtVer do
  let(:scheme) { described_class.new }

  describe "#parse" do
    it "parses WendtVer versions" do
      version = scheme.parse("1.2.3.4")
      expect(version.raw_string).to eq("1.2.3.4")
      expect(version.component(:major).value).to eq(1)
      expect(version.component(:minor).value).to eq(2)
      expect(version.component(:patch).value).to eq(3)
      expect(version.component(:build).value).to eq(4)
    end

    it "raises error for out of range minor" do
      expect { scheme.parse("1.100.3.4") }.to raise_error(Versionian::Errors::ParseError)
    end

    it "raises error for out of range patch" do
      expect { scheme.parse("1.2.100.4") }.to raise_error(Versionian::Errors::ParseError)
    end

    it "raises error for out of range build" do
      expect { scheme.parse("1.2.3.1000") }.to raise_error(Versionian::Errors::ParseError)
    end

    it "raises error for empty string" do
      expect { scheme.parse("") }.to raise_error(Versionian::Errors::InvalidVersionError)
    end

    it "raises error for invalid format" do
      expect { scheme.parse("1.2.3") }.to raise_error(Versionian::Errors::ParseError)
    end
  end

  describe "#compare" do
    it "compares versions correctly" do
      expect(scheme.compare("1.2.3.4", "1.2.3.5")).to eq(-1)
      expect(scheme.compare("1.2.3.4", "1.2.4.0")).to eq(-1)
      expect(scheme.compare("1.2.3.4", "2.0.0.0")).to eq(-1)
      expect(scheme.compare("1.2.3.5", "1.2.3.4")).to eq(1)
      expect(scheme.compare("1.2.3.4", "1.2.3.4")).to eq(0)
    end
  end

  describe "#valid?" do
    it "returns true for valid WendtVer versions" do
      expect(scheme.valid?("1.2.3.4")).to be true
      expect(scheme.valid?("0.0.0.0")).to be true
      expect(scheme.valid?("99.99.99.999")).to be true
    end

    it "returns false for invalid versions" do
      expect(scheme.valid?("")).to be false
      expect(scheme.valid?("1.2.3")).to be false
      expect(scheme.valid?("invalid")).to be false
    end
  end

  describe "#matches_range?" do
    it "matches equals range" do
      range = Versionian::VersionRange.new(:equals, scheme, version: "1.2.3.4")
      expect(scheme.matches_range?("1.2.3.4", range)).to be true
      expect(scheme.matches_range?("1.2.3.5", range)).to be false
    end

    it "matches after range" do
      range = Versionian::VersionRange.new(:after, scheme, version: "1.0.0.0")
      expect(scheme.matches_range?("1.2.3.4", range)).to be true
      expect(scheme.matches_range?("0.99.99.999", range)).to be false
    end

    it "matches between range" do
      range = Versionian::VersionRange.new(:between, scheme, from: "1.0.0.0", to: "2.0.0.0")
      expect(scheme.matches_range?("1.5.0.0", range)).to be true
      expect(scheme.matches_range?("2.0.0.1", range)).to be false
    end
  end

  describe "#render" do
    it "renders version" do
      version = scheme.parse("1.2.3.4")
      expect(version.to_s).to eq("1.2.3.4")
    end
  end

  describe "#increment" do
    it "increments build number" do
      expect(scheme.increment("1.2.3.4", :build)).to eq("1.2.3.5")
    end

    it "carries over from build to patch" do
      expect(scheme.increment("1.2.3.999", :build)).to eq("1.2.4.0")
    end

    it "carries over from patch to minor" do
      expect(scheme.increment("1.2.99.999", :build)).to eq("1.3.0.0")
    end

    it "carries over from minor to major" do
      expect(scheme.increment("1.99.99.999", :build)).to eq("2.0.0.0")
    end

    it "increments patch directly" do
      expect(scheme.increment("1.2.3.4", :patch)).to eq("1.2.4.4")
    end

    it "increments minor directly" do
      expect(scheme.increment("1.2.3.4", :minor)).to eq("1.3.3.4")
    end

    it "increments major directly" do
      expect(scheme.increment("1.2.3.4", :major)).to eq("2.2.3.4")
    end

    it "defaults to build increment" do
      expect(scheme.increment("1.2.3.4")).to eq("1.2.3.5")
    end
  end
end

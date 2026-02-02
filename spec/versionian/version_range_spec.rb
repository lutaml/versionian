# frozen_string_literal: true

RSpec.describe Versionian::VersionRange do
  let(:scheme) { Versionian::Schemes::Semantic.new }

  describe "#initialize" do
    it "creates an equals range" do
      range = described_class.new(:equals, scheme, version: "1.2.3")
      expect(range.type).to eq(:equals)
      expect(range.boundary).to eq("1.2.3")
    end

    it "creates a before range" do
      range = described_class.new(:before, scheme, version: "1.2.3")
      expect(range.type).to eq(:before)
      expect(range.boundary).to eq("1.2.3")
    end

    it "creates an after range" do
      range = described_class.new(:after, scheme, version: "1.2.3")
      expect(range.type).to eq(:after)
      expect(range.boundary).to eq("1.2.3")
    end

    it "creates a between range" do
      range = described_class.new(:between, scheme, from: "1.2.3", to: "2.0.0")
      expect(range.type).to eq(:between)
      expect(range.from).to eq("1.2.3")
      expect(range.to).to eq("2.0.0")
    end

    it "raises error for invalid range type" do
      expect { described_class.new(:invalid, scheme, version: "1.2.3") }.to raise_error(ArgumentError)
    end

    it "raises error for missing boundary" do
      expect { described_class.new(:equals, scheme) }.to raise_error(ArgumentError)
    end

    it "freezes the range" do
      range = described_class.new(:equals, scheme, version: "1.2.3")
      expect(range).to be_frozen
    end
  end

  describe "#matches?" do
    it "matches equals range" do
      range = described_class.new(:equals, scheme, version: "1.2.3")
      expect(range.matches?("1.2.3")).to be true
      expect(range.matches?("1.2.4")).to be false
    end

    it "matches before range" do
      range = described_class.new(:before, scheme, version: "1.2.3")
      expect(range.matches?("1.2.2")).to be true
      expect(range.matches?("1.2.3")).to be false
      expect(range.matches?("1.2.4")).to be false
    end

    it "matches after range" do
      range = described_class.new(:after, scheme, version: "1.2.3")
      expect(range.matches?("1.2.2")).to be false
      expect(range.matches?("1.2.3")).to be true
      expect(range.matches?("1.2.4")).to be true
    end

    it "matches between range" do
      range = described_class.new(:between, scheme, from: "1.2.0", to: "1.3.0")
      expect(range.matches?("1.1.9")).to be false
      expect(range.matches?("1.2.0")).to be true
      expect(range.matches?("1.2.5")).to be true
      expect(range.matches?("1.3.0")).to be true
      expect(range.matches?("1.3.1")).to be false
    end
  end

  describe "#to_s" do
    it "returns string representation" do
      expect(described_class.new(:equals, scheme, version: "1.2.3").to_s).to eq("== 1.2.3")
      expect(described_class.new(:before, scheme, version: "1.2.3").to_s).to eq("< 1.2.3")
      expect(described_class.new(:after, scheme, version: "1.2.3").to_s).to eq(">= 1.2.3")
      expect(described_class.new(:between, scheme, from: "1.2.0", to: "1.3.0").to_s).to eq("1.2.0 - 1.3.0")
    end
  end
end

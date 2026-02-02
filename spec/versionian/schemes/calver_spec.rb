# frozen_string_literal: true

RSpec.describe Versionian::Schemes::CalVer do
  describe "#parse" do
    context "with YYYY.MM.DD format" do
      let(:scheme) { described_class.new(format: "YYYY.MM.DD") }

      it "parses calendar versions" do
        version = scheme.parse("2024.01.15")
        expect(version.raw_string).to eq("2024.01.15")
        expect(version.scheme).to eq(scheme)
      end

      it "has year component" do
        version = scheme.parse("2024.01.15")
        expect(version.component(:year)&.value).to eq(2024)
      end

      it "has month component" do
        version = scheme.parse("2024.01.15")
        expect(version.component(:month)&.value).to eq(1)
      end

      it "has day component" do
        version = scheme.parse("2024.01.15")
        expect(version.component(:day)&.value).to eq(15)
      end
    end

    context "with YYYY.MM format" do
      let(:scheme) { described_class.new(format: "YYYY.MM") }

      it "parses calendar versions without day" do
        version = scheme.parse("2024.01")
        expect(version.raw_string).to eq("2024.01")
        expect(version.component(:year)&.value).to eq(2024)
        expect(version.component(:month)&.value).to eq(1)
      end
    end

    context "with YY.0M.DD format" do
      let(:scheme) { described_class.new(format: "YY.0M.DD") }

      it "parses two-digit year formats" do
        version = scheme.parse("24.01.15")
        expect(version.raw_string).to eq("24.01.15")
      end
    end
  end

  describe "#compare" do
    let(:scheme) { described_class.new(format: "YYYY.MM.DD") }

    it "compares versions chronologically" do
      expect(scheme.compare("2024.01.01", "2024.01.02")).to eq(-1)
      expect(scheme.compare("2024.01.01", "2024.02.01")).to eq(-1)
      expect(scheme.compare("2024.01.01", "2025.01.01")).to eq(-1)
      expect(scheme.compare("2024.01.02", "2024.01.01")).to eq(1)
      expect(scheme.compare("2024.01.01", "2024.01.01")).to eq(0)
    end
  end

  describe "#valid?" do
    let(:scheme) { described_class.new(format: "YYYY.MM.DD") }

    it "returns true for valid versions" do
      expect(scheme.valid?("2024.01.15")).to be true
    end

    it "returns false for invalid versions" do
      expect(scheme.valid?("invalid")).to be false
      expect(scheme.valid?("2024.13.01")).to be false # Invalid month
    end
  end
end

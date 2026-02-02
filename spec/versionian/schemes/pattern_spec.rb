# frozen_string_literal: true

RSpec.describe Versionian::Schemes::Pattern do
  describe "#parse" do
    it "parses versions matching pattern" do
      scheme = described_class.new(
        name: :custom,
        pattern: '^(\d+)\.(\d+)\.(\d+)$',
        component_definitions: [
          { name: :major, type: :integer },
          { name: :minor, type: :integer },
          { name: :patch, type: :integer }
        ]
      )

      version = scheme.parse("1.2.3")
      expect(version.raw_string).to eq("1.2.3")
      expect(version.component(:major)&.value).to eq(1)
      expect(version.component(:minor)&.value).to eq(2)
      expect(version.component(:patch)&.value).to eq(3)
    end

    it "raises error for non-matching versions" do
      scheme = described_class.new(
        name: :custom,
        pattern: '^(\d+)\.(\d+)\.(\d+)$',
        component_definitions: [
          { name: :major, type: :integer },
          { name: :minor, type: :integer },
          { name: :patch, type: :integer }
        ]
      )

      expect { scheme.parse("invalid") }.to raise_error(Versionian::Errors::ParseError)
    end

    it "raises error for dangerous patterns" do
      expect do
        described_class.new(
          name: :custom,
          pattern: '^((\d+*)\d+)$',
          component_definitions: [{ name: :test, type: :integer }]
        )
      end.to raise_error(Versionian::Errors::InvalidSchemeError)
    end
  end

  describe "#compare" do
    let(:scheme) do
      described_class.new(
        name: :custom,
        pattern: '^(\d+)\.(\d+)\.(\d+)$',
        component_definitions: [
          { name: :major, type: :integer },
          { name: :minor, type: :integer },
          { name: :patch, type: :integer }
        ]
      )
    end

    it "compares versions lexicographically" do
      expect(scheme.compare("1.2.3", "1.2.4")).to eq(-1)
      expect(scheme.compare("1.2.3", "1.3.0")).to eq(-1)
      expect(scheme.compare("1.2.3", "2.0.0")).to eq(-1)
      expect(scheme.compare("1.2.4", "1.2.3")).to eq(1)
      expect(scheme.compare("1.2.3", "1.2.3")).to eq(0)
    end
  end
end

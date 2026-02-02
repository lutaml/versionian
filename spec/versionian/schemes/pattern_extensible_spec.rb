# frozen_string_literal: true

RSpec.describe Versionian::Schemes::Pattern do
  let(:scheme) do
    described_class.new(
      name: :test_pattern,
      pattern: '^(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?(?:-([a-z]+)-(\d+))?$',
      component_definitions: [
        { name: :major, type: :integer },
        { name: :minor, type: :integer },
        { name: :patch, type: :integer },
        { name: :patchlevel, type: :integer, optional: true },
        { name: :stage, type: :enum, values: [:alpha, :beta, :rc], order: [:alpha, :beta, :rc], optional: true },
        { name: :iteration, type: :integer, optional: true }
      ]
    )
  end

  describe "#parse" do
    it "parses basic version" do
      version = scheme.parse("1.2.3")
      expect(version.raw_string).to eq("1.2.3")
      expect(version.component(:major).value).to eq(1)
      expect(version.component(:minor).value).to eq(2)
      expect(version.component(:patch).value).to eq(3)
    end

    it "parses version with patchlevel" do
      version = scheme.parse("1.2.3.4")
      expect(version.raw_string).to eq("1.2.3.4")
      expect(version.component(:patchlevel).value).to eq(4)
    end

    it "parses version with stage" do
      version = scheme.parse("1.2.3-alpha-1")
      expect(version.raw_string).to eq("1.2.3-alpha-1")
      expect(version.component(:stage).value).to eq(:alpha)
      expect(version.component(:iteration).value).to eq(1)
    end
  end

  describe "#render with format_template" do
    context "with optional segments using [] syntax" do
      let(:scheme_with_format) do
        # Use - instead of # to avoid Ruby string interpolation issues with #{}
        described_class.new(
          name: :extensible,
          pattern: '^(\d+)\.(\d+)\.(\d+)(?:\.(\d+))?(?:-([a-z]+)-(\d+))?$',
          format_template: "{major}.{minor}.{patch}[.{patchlevel}][-{stage}-{iteration}]",
          component_definitions: [
            { name: :major, type: :integer },
            { name: :minor, type: :integer },
            { name: :patch, type: :integer },
            { name: :patchlevel, type: :integer, optional: true },
            { name: :stage, type: :enum, values: [:alpha, :beta, :rc], order: [:alpha, :beta, :rc], optional: true },
            { name: :iteration, type: :integer, optional: true }
          ]
        )
      end

      it "renders basic version" do
        version = scheme_with_format.parse("1.2.3")
        expect(version.to_s).to eq("1.2.3")
      end

      it "renders version with patchlevel" do
        version = scheme_with_format.parse("1.2.3.4")
        expect(version.to_s).to eq("1.2.3.4")
      end

      it "renders version with stage" do
        version = scheme_with_format.parse("1.2.3-alpha-1")
        expect(version.to_s).to eq("1.2.3-alpha-1")
      end

      it "renders version with both optional components" do
        version = scheme_with_format.parse("1.2.3.4-beta-2")
        expect(version.to_s).to eq("1.2.3.4-beta-2")
      end
    end

    context "without format_template" do
      it "returns raw_string" do
        version = scheme.parse("1.2.3")
        expect(version.to_s).to eq("1.2.3")
      end
    end
  end

  describe "#compare" do
    it "compares basic versions" do
      expect(scheme.compare("1.2.3", "1.2.4")).to eq(-1)
      expect(scheme.compare("1.2.3", "1.2.3")).to eq(0)
    end

    it "compares versions with optional components" do
      expect(scheme.compare("1.2.3", "1.2.3.4")).to eq(-1)
      expect(scheme.compare("1.2.3-alpha-1", "1.2.3-beta-1")).to eq(-1)
    end
  end
end

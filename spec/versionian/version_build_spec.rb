# frozen_string_literal: true

RSpec.describe Versionian::VersionScheme do
  let(:pattern_scheme) do
    Versionian::Schemes::Pattern.new(
      name: :build_test,
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

  describe "#build" do
    it "builds a Version from component values" do
      version = pattern_scheme.build(major: 1, minor: 2, patch: 3)

      expect(version).to be_a(Versionian::VersionIdentifier)
      expect(version.to_s).to eq("1.2.3")
      expect(version.component(:major).value).to eq(1)
      expect(version.component(:minor).value).to eq(2)
      expect(version.component(:patch).value).to eq(3)
    end

    it "builds a Version with optional components" do
      version = pattern_scheme.build(major: 1, minor: 2, patch: 3, patchlevel: 4)

      expect(version.to_s).to eq("1.2.3.4")
      expect(version.component(:patchlevel).value).to eq(4)
    end

    it "builds a Version with stage and iteration" do
      version = pattern_scheme.build(major: 1, minor: 2, patch: 3, stage: :alpha, iteration: 1)

      expect(version.to_s).to eq("1.2.3-alpha-1")
      expect(version.component(:stage).value).to eq(:alpha)
      expect(version.component(:iteration).value).to eq(1)
    end

    it "builds a Version with all components" do
      version = pattern_scheme.build(major: 1, minor: 2, patch: 3, patchlevel: 4, stage: :beta, iteration: 2)

      expect(version.to_s).to eq("1.2.3.4-beta-2")
    end
  end

  describe "parse vs build" do
    it "produces equivalent Versions from parse and build" do
      parsed = pattern_scheme.parse("1.2.3")
      built = pattern_scheme.build(major: 1, minor: 2, patch: 3)

      expect(parsed.to_s).to eq(built.to_s)
      expect(parsed).to eq(built)
    end

    it "allows comparison between parsed and built versions" do
      parsed = pattern_scheme.parse("1.2.3")
      built = pattern_scheme.build(major: 1, minor: 2, patch: 4)

      expect(parsed).to be < built
      expect(built).to be > parsed
    end
  end
end

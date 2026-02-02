# frozen_string_literal: true

RSpec.describe Versionian::SchemeLoader do
  describe ".from_yaml_string" do
    it "loads pattern scheme from YAML" do
      yaml = <<~YAML
        name: custom
        type: pattern
        pattern: '^(\d+)\.(\d+)$'
        components:
          - name: major
            type: integer
          - name: minor
            type: integer
      YAML

      scheme = described_class.from_yaml_string(yaml)
      expect(scheme).to be_a(Versionian::Schemes::Pattern)
      expect(scheme.name).to eq(:custom)
    end

    it "loads declarative scheme from YAML" do
      yaml = <<~YAML
        name: semantic_like
        type: declarative
        description: Semantic versioning scheme
        components:
          - name: major
            type: integer
            separator: "."
          - name: minor
            type: integer
            separator: "."
          - name: patch
            type: integer
      YAML

      scheme = described_class.from_yaml_string(yaml)
      expect(scheme).to be_a(Versionian::Schemes::Declarative)
      expect(scheme.name).to eq(:semantic_like)
      expect(scheme.description).to eq("Semantic versioning scheme")
    end

    it "loads declarative scheme with optional segments" do
      yaml = <<~YAML
        name: with_prerelease
        type: declarative
        components:
          - name: major
            type: integer
            separator: "."
          - name: minor
            type: integer
            separator: "."
          - name: prerelease
            type: string
            prefix: "-"
            optional: true
      YAML

      scheme = described_class.from_yaml_string(yaml)
      expect(scheme).to be_a(Versionian::Schemes::Declarative)

      version = scheme.parse("1.2-alpha")
      expect(version.raw_string).to eq("1.2-alpha")
    end

    it "loads declarative scheme with include_prefix_in_value" do
      yaml = <<~YAML
        name: solover
        type: declarative
        components:
          - name: number
            type: integer
          - name: postfix
            type: postfix
            prefix: "+"
            optional: true
            include_prefix_in_value: true
      YAML

      scheme = described_class.from_yaml_string(yaml)
      expect(scheme).to be_a(Versionian::Schemes::Declarative)

      version = scheme.parse("5+hotfix")
      expect(version.raw_string).to eq("5+hotfix")
    end

    it "loads calver scheme from YAML" do
      yaml = <<~YAML
        name: my_calver
        type: calver
        format: YYYY.MM.DD
      YAML

      scheme = described_class.from_yaml_string(yaml)
      expect(scheme).to be_a(Versionian::Schemes::CalVer)
      expect(scheme.format).to eq("YYYY.MM.DD")
    end

    it "raises error for invalid YAML" do
      yaml = "invalid: yaml: content: ["

      expect { described_class.from_yaml_string(yaml) }.to raise_error(Versionian::Errors::InvalidSchemeError)
    end

    it "raises error for unknown scheme type" do
      yaml = <<~YAML
        name: custom
        type: unknown
      YAML

      expect { described_class.from_yaml_string(yaml) }.to raise_error(Versionian::Errors::InvalidSchemeError)
    end
  end

  describe ".from_hash" do
    it "creates pattern scheme from hash" do
      hash = {
        "name" => "custom",
        "type" => "pattern",
        "pattern" => '^(\d+)\.(\d+)$',
        "components" => [
          { "name" => "major", "type" => "integer" },
          { "name" => "minor", "type" => "integer" }
        ]
      }

      scheme = described_class.from_hash(hash)
      expect(scheme).to be_a(Versionian::Schemes::Pattern)
    end

    it "creates declarative scheme from hash" do
      hash = {
        "name" => "simple",
        "type" => "declarative",
        "components" => [
          { "name" => "major", "type" => "integer", "separator" => "." },
          { "name" => "minor", "type" => "integer" }
        ]
      }

      scheme = described_class.from_hash(hash)
      expect(scheme).to be_a(Versionian::Schemes::Declarative)
      expect(scheme.name).to eq(:simple)
    end

    it "creates calver scheme from hash" do
      hash = {
        "name" => "my_calver",
        "type" => "calver",
        "format" => "YYYY.MM.DD"
      }

      scheme = described_class.from_hash(hash)
      expect(scheme).to be_a(Versionian::Schemes::CalVer)
    end
  end
end

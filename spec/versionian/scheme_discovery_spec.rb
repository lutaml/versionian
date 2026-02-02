# frozen_string_literal: true

RSpec.describe "Scheme Discovery API" do
  describe "Versionian.scheme_registry.registered" do
    it "returns array of registered scheme names" do
      registered = Versionian.scheme_registry.registered

      expect(registered).to be_an(Array)
      expect(registered).to include(:semantic)
      expect(registered).to include(:calver)
      expect(registered).to include(:solover)
      expect(registered).to include(:wendtver)
    end

    it "includes built-in schemes" do
      registered = Versionian.scheme_registry.registered

      # At minimum, these 4 built-in schemes should be registered
      expect(registered.size).to be >= 4
      expect(registered).to contain_exactly(:semantic, :calver, :solover, :wendtver)
    end
  end

  describe "Versionian.detect_scheme" do
    it "detects semantic versioning" do
      scheme = Versionian.detect_scheme("1.2.3")
      expect(scheme).to be_a(Versionian::Schemes::Semantic)
      expect(scheme.name).to eq(:semantic)
    end

    it "detects calendar versioning" do
      scheme = Versionian.detect_scheme("2024.01.17")
      expect(scheme).to be_a(Versionian::Schemes::CalVer)
      expect(scheme.name).to eq(:calver)
    end

    it "detects solover versioning" do
      scheme = Versionian.detect_scheme("5+hotfix")
      expect(scheme).to be_a(Versionian::Schemes::SoloVer)
      expect(scheme.name).to eq(:solover)
    end

    it "detects wendtver versioning" do
      scheme = Versionian.detect_scheme("1.2.3.4")
      expect(scheme).to be_a(Versionian::Schemes::WendtVer)
      expect(scheme.name).to eq(:wendtver)
    end

    it "returns nil for unrecognised version strings" do
      scheme = Versionian.detect_scheme("not-a-version")
      expect(scheme).to be_nil
    end

    it "returns nil for empty string" do
      scheme = Versionian.detect_scheme("")
      expect(scheme).to be_nil
    end

    it "returns nil for nil input" do
      scheme = Versionian.detect_scheme(nil)
      expect(scheme).to be_nil
    end

    it "prefers more specific schemes when multiple match" do
      # Both WendtVer and Semantic could match "1.2.3.4"
      # WendtVer should be detected since it's more specific
      scheme = Versionian.detect_scheme("1.2.3.4")
      expect(scheme.name).to eq(:wendtver)
    end
  end

  describe "Versionian.get_scheme" do
    it "returns scheme by name" do
      scheme = Versionian.get_scheme(:semantic)
      expect(scheme).to be_a(Versionian::Schemes::Semantic)
      expect(scheme.name).to eq(:semantic)
    end

    it "returns calver scheme" do
      scheme = Versionian.get_scheme(:calver)
      expect(scheme).to be_a(Versionian::Schemes::CalVer)
      expect(scheme.name).to eq(:calver)
    end

    it "returns solover scheme" do
      scheme = Versionian.get_scheme(:solover)
      expect(scheme).to be_a(Versionian::Schemes::SoloVer)
      expect(scheme.name).to eq(:solover)
    end

    it "returns wendtver scheme" do
      scheme = Versionian.get_scheme(:wendtver)
      expect(scheme).to be_a(Versionian::Schemes::WendtVer)
      expect(scheme.name).to eq(:wendtver)
    end

    it "raises error for unknown scheme" do
      expect do
        Versionian.get_scheme(:unknown)
      end.to raise_error(Versionian::Errors::InvalidSchemeError, /Unknown scheme: unknown/)
    end
  end
end

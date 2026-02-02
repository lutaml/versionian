# frozen_string_literal: true

RSpec.describe Versionian::SchemeRegistry do
  let(:registry) { described_class.instance }

  before do
    # Reset registry for clean tests
    registry.instance_variable_set(:@schemes, {})
  end

  describe "#register" do
    it "registers a scheme" do
      scheme = Versionian::Schemes::Semantic.new
      registry.register(:test, scheme)

      expect(registry.registered).to include(:test)
    end
  end

  describe "#get" do
    before do
      scheme = Versionian::Schemes::Semantic.new
      registry.register(:semantic, scheme)
    end

    it "returns registered scheme" do
      scheme = registry.get(:semantic)
      expect(scheme).to be_a(Versionian::Schemes::Semantic)
    end

    it "raises error for unknown scheme" do
      expect { registry.get(:unknown) }.to raise_error(Versionian::Errors::InvalidSchemeError)
    end
  end

  describe "#detect_from" do
    before do
      registry.register(:semantic, Versionian::Schemes::Semantic.new)
      registry.register(:calver, Versionian::Schemes::CalVer.new)
    end

    it "detects scheme from version string" do
      scheme = registry.detect_from("1.2.3")
      expect(scheme).to be_a(Versionian::Schemes::Semantic)
    end

    it "detects calver scheme from version string" do
      scheme = registry.detect_from("2024.01.15")
      expect(scheme).to be_a(Versionian::Schemes::CalVer)
    end

    it "returns nil for unknown formats" do
      scheme = registry.detect_from("invalid-format")
      expect(scheme).to be_nil
    end
  end

  describe "#registered" do
    it "returns list of registered scheme names" do
      registry.register(:scheme1, Versionian::Schemes::Semantic.new)
      registry.register(:scheme2, Versionian::Schemes::CalVer.new)

      expect(registry.registered).to include(:scheme1, :scheme2)
    end
  end
end

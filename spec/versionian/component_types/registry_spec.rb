# frozen_string_literal: true

RSpec.describe Versionian::ComponentTypes do
  describe ".register" do
    it "registers a component type" do
      # Create a new registry instance for testing
      described_class.register(:test_type_custom, Versionian::ComponentTypes::Integer)
      expect(described_class.registered).to include(:test_type_custom)
    end
  end

  describe ".resolve" do
    it "resolves registered type" do
      expect(described_class.resolve(:integer)).to eq(Versionian::ComponentTypes::Integer)
    end

    it "raises error for unknown type" do
      expect { described_class.resolve(:unknown_type_xyz) }.to raise_error(Versionian::Errors::InvalidSchemeError)
    end
  end

  describe ".registered" do
    it "returns list of registered types" do
      expect(described_class.registered).to include(:integer, :float, :string, :enum)
    end
  end
end

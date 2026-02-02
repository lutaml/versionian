# frozen_string_literal: true

RSpec.describe Versionian::VersionComponent do
  let(:component) do
    described_class.new(
      name: :major,
      type: :integer,
      value: 1,
      weight: 1
    )
  end

  describe "#initialize" do
    it "creates a component with attributes" do
      expect(component.name).to eq(:major)
      expect(component.type).to eq(:integer)
      expect(component.value).to eq(1)
      expect(component.weight).to eq(1)
    end

    it "freezes the component" do
      expect(component).to be_frozen
    end
  end

  describe "#to_comparable" do
    it "returns the comparable value" do
      expect(component.to_comparable).to eq(1)
    end
  end

  describe "#to_s" do
    it "formats the value" do
      expect(component.to_s).to eq("1")
    end
  end
end

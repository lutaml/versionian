# frozen_string_literal: true

RSpec.describe Versionian::Errors::InvalidVersionError do
  it "is a StandardError" do
    expect(described_class).to be < StandardError
  end
end

# frozen_string_literal: true

RSpec.describe Versionian::Errors::ParseError do
  it "is a StandardError" do
    expect(described_class).to be < StandardError
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Text do
  let(:to) { "+16505551234" }

  describe "#serialize" do
    subject(:serialized) { described_class.new(to:, body: "Hello").serialize }

    it "builds the common envelope" do
      expect(serialized).to include(
        messaging_product: "whatsapp",
        recipient_type: "individual",
        to:,
        type: "text"
      )
    end

    it "nests the body and preview_url under text" do
      expect(serialized[:text]).to eq(body: "Hello", preview_url: true)
    end
  end

  describe "validation" do
    it "requires a body" do
      expect { described_class.new(to:, body: nil) }.to raise_error(ActiveModel::ValidationError)
    end

    it "rejects a body longer than 4096 characters" do
      expect { described_class.new(to:, body: "a" * 4097) }.to raise_error(ActiveModel::ValidationError)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Context do
  describe ".deserialize" do
    it "maps from, id, forwarded, and frequently_forwarded" do
      context = described_class.deserialize(
        "from" => "16505551234",
        "id" => "wamid.HBg",
        "forwarded" => true,
        "frequently_forwarded" => false
      )

      expect(context.from).to eq("16505551234")
      expect(context.id).to eq("wamid.HBg")
      expect(context.forwarded).to be(true)
      expect(context.frequently_forwarded).to be(false)
    end

    it "returns nil when there is no context" do
      expect(described_class.deserialize(nil)).to be_nil
    end
  end
end

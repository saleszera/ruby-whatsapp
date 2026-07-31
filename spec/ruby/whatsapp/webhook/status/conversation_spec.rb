# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Status::Conversation do
  describe ".deserialize" do
    it "maps id, origin.type, and expiration_timestamp" do
      conversation = described_class.deserialize(
        "id" => "6ceb9d9",
        "origin" => { "type" => "service" },
        "expiration_timestamp" => "1750267373"
      )

      expect(conversation.id).to eq("6ceb9d9")
      expect(conversation.origin_type).to eq("service")
      expect(conversation.expiration_timestamp).to eq("1750267373")
    end
  end
end

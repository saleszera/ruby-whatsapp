# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Reaction do
  describe ".deserialize" do
    it "maps message_id and emoji" do
      message = described_class.deserialize(
        "type" => "reaction",
        "reaction" => { "message_id" => "wamid.OLD", "emoji" => "\u{1F44D}" }
      )

      expect(message.message_id).to eq("wamid.OLD")
      expect(message.emoji).to eq("\u{1F44D}")
    end
  end
end

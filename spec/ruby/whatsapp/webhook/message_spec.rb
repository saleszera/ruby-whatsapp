# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message do
  describe ".deserialize" do
    it "dispatches a text message to Message::Text" do
      message = described_class.deserialize(
        "from" => "16505551234",
        "id" => "wamid.HBg",
        "timestamp" => "1749416383",
        "type" => "text",
        "text" => { "body" => "Does it come in another color?" }
      )

      expect(message).to be_a(Whatsapp::Webhook::Message::Text)
      expect(message.from).to eq("16505551234")
      expect(message.body).to eq("Does it come in another color?")
    end

    it "falls back to Message::Unknown for an unrecognized type" do
      message = described_class.deserialize("type" => "some_future_type", "from" => "1")

      expect(message).to be_a(Whatsapp::Webhook::Message::Unknown)
    end

    it "dispatches a revoke to Message::Revoke rather than the Unknown fallback" do
      message = described_class.deserialize(
        "id" => "wamid.HBg", "timestamp" => "1", "type" => "revoke",
        "revoke" => { "original_message_id" => "wamid.ORIGINAL" }
      )

      expect(message).to be_a(Whatsapp::Webhook::Message::Revoke)
      expect(message.original_message_id).to eq("wamid.ORIGINAL")
    end

    it "dispatches an edit to Message::Edit rather than the Unknown fallback" do
      message = described_class.deserialize(
        "id" => "wamid.HBg", "timestamp" => "1", "type" => "edit",
        "edit" => { "original_message_id" => "wamid.ORIGINAL",
                    "message" => { "type" => "text", "text" => { "body" => "fixed" } }, }
      )

      expect(message).to be_a(Whatsapp::Webhook::Message::Edit)
      expect(message.message.body).to eq("fixed")
    end
  end
end

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
  end
end

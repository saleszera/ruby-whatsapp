# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Notification do
  describe ".deserialize" do
    it "maps object and entry" do
      notification = described_class.deserialize(
        "object" => "whatsapp_business_account",
        "entry" => [{ "id" => "102290129340398", "changes" => [] }]
      )

      expect(notification.object).to eq("whatsapp_business_account")
      expect(notification.entry.length).to eq(1)
      expect(notification.entry.first).to be_a(Whatsapp::Webhook::Entry)
    end

    it "tolerates missing entry" do
      notification = described_class.deserialize("object" => "whatsapp_business_account")

      expect(notification.entry).to eq([])
    end

    it "deserializes a full real-world inbound text message payload end to end" do
      data = {
        "object" => "whatsapp_business_account",
        "entry" => [
          {
            "id" => "102290129340398",
            "changes" => [
              {
                "value" => {
                  "messaging_product" => "whatsapp",
                  "metadata" => { "display_phone_number" => "15550783881", "phone_number_id" => "106540352242922" },
                  "contacts" => [{ "profile" => { "name" => "Sheena Nelson" }, "wa_id" => "16505551234" }],
                  "messages" => [
                    { "from" => "16505551234", "id" => "wamid.HBg", "timestamp" => "1749416383", "type" => "text",
                      "text" => { "body" => "Does it come in another color?" }, },
                  ],
                },
                "field" => "messages",
              },
            ],
          },
        ],
      }

      notification = described_class.deserialize(data)
      message = notification.entry.first.changes.first.value.messages.first

      expect(notification.object).to eq("whatsapp_business_account")
      expect(message).to be_a(Whatsapp::Webhook::Message::Text)
      expect(message.body).to eq("Does it come in another color?")
      expect(message.from).to eq("16505551234")
    end
  end
end

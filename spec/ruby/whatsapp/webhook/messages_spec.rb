# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Messages do
  describe ".deserialize" do
    it "maps messaging_product, metadata, contacts, and messages" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "15550783881", "phone_number_id" => "106540352242922" },
        "contacts" => [{ "profile" => { "name" => "Sheena Nelson" }, "wa_id" => "16505551234" }],
        "messages" => [
          { "from" => "16505551234", "id" => "wamid.HBg", "timestamp" => "1749416383", "type" => "text",
            "text" => { "body" => "Does it come in another color?" }, },
        ]
      )

      expect(value.messaging_product).to eq("whatsapp")
      expect(value.metadata).to be_a(Whatsapp::Webhook::Metadata)
      expect(value.metadata.phone_number_id).to eq("106540352242922")
      expect(value.contacts.first).to be_a(Whatsapp::Webhook::Contact)
      expect(value.contacts.first.wa_id).to eq("16505551234")
      expect(value.messages.first).to be_a(Whatsapp::Webhook::Message::Text)
      expect(value.messages.first.body).to eq("Does it come in another color?")
      expect(value.statuses).to eq([])
    end

    it "maps statuses" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "statuses" => [{ "id" => "wamid.HBg", "status" => "delivered", "recipient_id" => "16505551234" }]
      )

      expect(value.statuses.first).to be_a(Whatsapp::Webhook::Status)
      expect(value.statuses.first.status).to eq("delivered")
      expect(value.contacts).to eq([])
      expect(value.messages).to eq([])
    end
  end
end

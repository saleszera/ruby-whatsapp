# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::SmbMessageEchoes do
  describe ".deserialize" do
    it "maps messaging_product, metadata, and message_echoes (reusing Message.deserialize)" do
      value = described_class.deserialize(
        "messaging_product" => "whatsapp",
        "metadata" => { "display_phone_number" => "15550783881", "phone_number_id" => "106540352242922" },
        "message_echoes" => [
          { "from" => "15550783881", "type" => "text", "text" => { "body" => "Thanks for shopping with us!" } },
        ]
      )

      expect(value.messaging_product).to eq("whatsapp")
      expect(value.metadata).to be_a(Whatsapp::Webhook::Metadata)
      expect(value.message_echoes.first).to be_a(Whatsapp::Webhook::Message::Text)
      expect(value.message_echoes.first.body).to eq("Thanks for shopping with us!")
    end

    it "tolerates a missing message_echoes array" do
      value = described_class.deserialize({})

      expect(value.message_echoes).to eq([])
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Text do
  describe ".deserialize" do
    it "maps the envelope and the text body" do
      message = described_class.deserialize(
        "from" => "16505551234",
        "id" => "wamid.HBg",
        "timestamp" => "1749416383",
        "type" => "text",
        "text" => { "body" => "Does it come in another color?" }
      )

      expect(message.from).to eq("16505551234")
      expect(message.id).to eq("wamid.HBg")
      expect(message.timestamp).to eq("1749416383")
      expect(message.type).to eq("text")
      expect(message.body).to eq("Does it come in another color?")
      expect(message.context).to be_nil
    end

    it "deserializes the context when present" do
      message = described_class.deserialize(
        "type" => "text",
        "text" => { "body" => "yes" },
        "context" => { "from" => "1", "id" => "wamid.OLD" }
      )

      expect(message.context).to be_a(Whatsapp::Webhook::Message::Context)
      expect(message.context.id).to eq("wamid.OLD")
    end
  end
end

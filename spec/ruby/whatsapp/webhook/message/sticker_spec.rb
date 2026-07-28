# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Sticker do
  describe ".deserialize" do
    it "maps media_id, mime_type, sha256, and animated" do
      message = described_class.deserialize(
        "type" => "sticker",
        "sticker" => { "id" => "med.5", "mime_type" => "image/webp", "sha256" => "abc", "animated" => false }
      )

      expect(message.media_id).to eq("med.5")
      expect(message.animated).to be(false)
    end
  end
end

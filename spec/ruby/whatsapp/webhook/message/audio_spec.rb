# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Audio do
  describe ".deserialize" do
    it "maps media_id, mime_type, sha256, and voice" do
      message = described_class.deserialize(
        "type" => "audio",
        "audio" => { "id" => "med.3", "mime_type" => "audio/ogg", "sha256" => "abc", "voice" => true }
      )

      expect(message.media_id).to eq("med.3")
      expect(message.mime_type).to eq("audio/ogg")
      expect(message.voice).to be(true)
    end
  end
end

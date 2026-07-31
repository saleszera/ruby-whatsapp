# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Video do
  describe ".deserialize" do
    it "maps media_id, mime_type, sha256, and caption" do
      message = described_class.deserialize(
        "type" => "video",
        "video" => { "id" => "med.2", "mime_type" => "video/mp4", "sha256" => "abc", "caption" => "Demo" }
      )

      expect(message.media_id).to eq("med.2")
      expect(message.mime_type).to eq("video/mp4")
      expect(message.sha256).to eq("abc")
      expect(message.caption).to eq("Demo")
    end
  end
end

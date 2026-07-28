# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Image do
  describe ".deserialize" do
    it "maps id, mime_type, sha256, and caption" do
      message = described_class.deserialize(
        "type" => "image",
        "image" => { "id" => "med.1", "mime_type" => "image/jpeg", "sha256" => "abc", "caption" => "Nice!" }
      )

      expect(message.media_id).to eq("med.1")
      expect(message.mime_type).to eq("image/jpeg")
      expect(message.sha256).to eq("abc")
      expect(message.caption).to eq("Nice!")
    end
  end
end

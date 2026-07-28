# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Document do
  describe ".deserialize" do
    it "maps media_id, mime_type, sha256, caption, and filename" do
      message = described_class.deserialize(
        "type" => "document",
        "document" => {
          "id" => "med.4", "mime_type" => "application/pdf", "sha256" => "abc",
          "caption" => "Invoice", "filename" => "invoice.pdf",
        }
      )

      expect(message.media_id).to eq("med.4")
      expect(message.filename).to eq("invoice.pdf")
      expect(message.caption).to eq("Invoice")
    end
  end
end

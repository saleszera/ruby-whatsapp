# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Referral do
  describe ".deserialize" do
    it "maps every referral field" do
      referral = described_class.deserialize(
        "source_url" => "https://fb.me/ad",
        "source_type" => "ad",
        "source_id" => "123",
        "headline" => "Big sale",
        "body" => "50% off",
        "media_type" => "image",
        "image_url" => "https://example.com/a.jpg",
        "video_url" => nil,
        "thumbnail_url" => "https://example.com/thumb.jpg"
      )

      expect(referral.source_url).to eq("https://fb.me/ad")
      expect(referral.source_type).to eq("ad")
      expect(referral.headline).to eq("Big sale")
      expect(referral.media_type).to eq("image")
      expect(referral.thumbnail_url).to eq("https://example.com/thumb.jpg")
    end

    it "returns nil when there is no referral" do
      expect(described_class.deserialize(nil)).to be_nil
    end
  end
end

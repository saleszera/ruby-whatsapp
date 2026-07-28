# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Sticker do
  let(:to) { "+16505551234" }

  describe "validation" do
    it "is valid with an id" do
      expect { described_class.new(to:, id: "MEDIA_ID") }.not_to raise_error
    end

    it "is valid with a link" do
      expect { described_class.new(to:, link: "https://example.com/s.webp") }.not_to raise_error
    end

    it "raises when neither id nor link is present" do
      expect { described_class.new(to:) }
        .to raise_error(ActiveModel::ValidationError, /Either id or link must be present/)
    end
  end

  describe "#serialize" do
    it "omits nil fields from the sticker payload" do
      serialized = described_class.new(to:, id: "MEDIA_ID").serialize
      expect(serialized[:type]).to eq("sticker")
      expect(serialized[:sticker]).to eq(id: "MEDIA_ID")
    end
  end
end

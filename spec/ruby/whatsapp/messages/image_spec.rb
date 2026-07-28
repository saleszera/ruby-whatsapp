# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Image do
  let(:to) { "+16505551234" }
  let(:media_id) { "1234567890" }
  let(:media_url) { "https://example.com/image.jpg" }

  describe "#initialize" do
    context "with id" do
      it "is valid" do
        expect { described_class.new(to:, id: media_id) }.not_to raise_error
      end
    end

    context "with link" do
      it "is valid" do
        expect { described_class.new(to:, link: media_url) }.not_to raise_error
      end
    end

    context "with id and caption" do
      it "is valid" do
        expect { described_class.new(to:, id: media_id, caption: "Hello") }.not_to raise_error
      end
    end

    context "without id or link" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(to:) }
          .to raise_error(ActiveModel::ValidationError, /Either id or link must be present/)
      end
    end

    context "without to" do
      it "raises ArgumentError" do
        expect { described_class.new(id: media_id) }
          .to raise_error(ArgumentError, /missing keyword: :?to/)
      end
    end

    context "with caption exceeding 1024 characters" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(to:, id: media_id, caption: "a" * 1025) }
          .to raise_error(ActiveModel::ValidationError, /Caption is too long \(maximum is 1024 characters\)/)
      end
    end
  end

  describe "#serialize" do
    subject(:serialized) { image.serialize }

    context "with id" do
      let(:image) { described_class.new(to:, id: media_id) }

      it "returns the correct type" do
        expect(serialized[:type]).to eq("image")
      end

      it "includes messaging product and recipient type" do
        expect(serialized[:messaging_product]).to eq("whatsapp")
        expect(serialized[:recipient_type]).to eq("individual")
      end

      it "includes the recipient phone number" do
        expect(serialized[:to]).to eq(to)
      end

      it "includes the media id in the image payload" do
        expect(serialized[:image][:id]).to eq(media_id)
      end

      it "omits nil fields from the image payload" do
        expect(serialized[:image]).not_to have_key(:link)
        expect(serialized[:image]).not_to have_key(:caption)
      end
    end

    context "with link" do
      let(:image) { described_class.new(to:, link: media_url) }

      it "includes the media link in the image payload" do
        expect(serialized[:image][:link]).to eq(media_url)
      end

      it "omits nil fields from the image payload" do
        expect(serialized[:image]).not_to have_key(:id)
        expect(serialized[:image]).not_to have_key(:caption)
      end
    end

    context "with caption" do
      let(:image) { described_class.new(to:, id: media_id, caption: "A sunset photo") }

      it "includes the caption in the image payload" do
        expect(serialized[:image][:caption]).to eq("A sunset photo")
      end
    end
  end
end

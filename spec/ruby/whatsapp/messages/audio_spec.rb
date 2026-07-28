# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Audio do
  let(:to) { Faker::PhoneNumber.cell_phone_in_e164 }
  let(:media_id) { Faker::Alphanumeric.alphanumeric(number: 16) }
  let(:media_url) { Faker::Internet.url(path: "/audio/#{Faker::File.file_name(ext: 'mp3')}") }

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
  end

  describe "#serialize" do
    context "with id" do
      subject(:serialized) { described_class.new(to:, id: media_id).serialize }

      it "returns the correct type" do
        expect(serialized[:type]).to eq("audio")
      end

      it "includes messaging product and recipient type" do
        expect(serialized[:messaging_product]).to eq("whatsapp")
        expect(serialized[:recipient_type]).to eq("individual")
      end

      it "includes the recipient phone number" do
        expect(serialized[:to]).to eq(to)
      end

      it "includes the media id in the audio payload" do
        expect(serialized[:audio][:id]).to eq(media_id)
      end

      it "omits nil fields from the audio payload" do
        expect(serialized[:audio]).not_to have_key(:link)
      end
    end

    context "with link" do
      subject(:serialized) { described_class.new(to:, link: media_url).serialize }

      it "includes the media link in the audio payload" do
        expect(serialized[:audio][:link]).to eq(media_url)
      end

      it "omits nil fields from the audio payload" do
        expect(serialized[:audio]).not_to have_key(:id)
      end
    end
  end
end

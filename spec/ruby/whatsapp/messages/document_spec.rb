# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Document do
  let(:to) { Faker::PhoneNumber.cell_phone_in_e164 }
  let(:media_id) { Faker::Alphanumeric.alphanumeric(number: 16) }
  let(:media_url) { Faker::Internet.url(path: "/docs/#{Faker::File.file_name(ext: 'pdf')}") }
  let(:caption) { Faker::Lorem.sentence }
  let(:filename) { Faker::File.file_name(ext: "pdf") }

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

    context "with id, caption, and filename" do
      it "is valid" do
        expect { described_class.new(to:, id: media_id, caption:, filename:) }.not_to raise_error
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
        long_caption = Faker::Lorem.characters(number: 1025)
        expect { described_class.new(to:, id: media_id, caption: long_caption) }
          .to raise_error(ActiveModel::ValidationError, /Caption is too long \(maximum is 1024 characters\)/)
      end
    end
  end

  describe "#serialize" do
    subject(:serialized) { document.serialize }

    context "with id" do
      let(:document) { described_class.new(to:, id: media_id) }

      it "returns the correct type" do
        expect(serialized[:type]).to eq("document")
      end

      it "includes messaging product and recipient type" do
        expect(serialized[:messaging_product]).to eq("whatsapp")
        expect(serialized[:recipient_type]).to eq("individual")
      end

      it "includes the recipient phone number" do
        expect(serialized[:to]).to eq(to)
      end

      it "includes the media id in the document payload" do
        expect(serialized[:document][:id]).to eq(media_id)
      end

      it "omits nil fields from the document payload" do
        expect(serialized[:document]).not_to have_key(:link)
        expect(serialized[:document]).not_to have_key(:caption)
        expect(serialized[:document]).not_to have_key(:filename)
      end
    end

    context "with link" do
      let(:document) { described_class.new(to:, link: media_url) }

      it "includes the media link in the document payload" do
        expect(serialized[:document][:link]).to eq(media_url)
      end

      it "omits nil fields from the document payload" do
        expect(serialized[:document]).not_to have_key(:id)
        expect(serialized[:document]).not_to have_key(:caption)
        expect(serialized[:document]).not_to have_key(:filename)
      end
    end

    context "with caption" do
      let(:document) { described_class.new(to:, id: media_id, caption:) }

      it "includes the caption in the document payload" do
        expect(serialized[:document][:caption]).to eq(caption)
      end
    end

    context "with filename" do
      let(:document) { described_class.new(to:, id: media_id, filename:) }

      it "includes the filename in the document payload" do
        expect(serialized[:document][:filename]).to eq(filename)
      end
    end
  end
end

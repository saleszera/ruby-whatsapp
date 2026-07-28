# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Contacts::Url do
  let(:url) { Faker::Internet.url }

  describe "#initialize" do
    context "with only url" do
      it "is valid" do
        expect { described_class.new(url:) }.not_to raise_error
      end
    end

    context "with type" do
      it "is valid" do
        expect { described_class.new(url:, type: described_class::Types::WORK) }.not_to raise_error
      end
    end

    context "without url" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(url: nil) }
          .to raise_error(ActiveModel::ValidationError, /Url can't be blank/)
      end
    end

    context "with invalid type" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(url:, type: "INVALID") }
          .to raise_error(ActiveModel::ValidationError, /Type is not included in the list/)
      end
    end
  end

  describe "#serialize" do
    context "with only url" do
      subject(:serialized) { described_class.new(url:).serialize }

      it "includes url" do
        expect(serialized[:url]).to eq(url)
      end

      it "omits nil optional fields" do
        expect(serialized).not_to have_key(:type)
      end
    end

    context "with type" do
      subject(:serialized) { described_class.new(url:, type: described_class::Types::WEBSITE).serialize }

      it "includes type" do
        expect(serialized[:type]).to eq(described_class::Types::WEBSITE)
      end
    end
  end
end

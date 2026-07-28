# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Contacts::Email do
  let(:email) { Faker::Internet.email }

  describe "#initialize" do
    context "with only email" do
      it "is valid" do
        expect { described_class.new(email:) }.not_to raise_error
      end
    end

    context "with type" do
      it "is valid" do
        expect { described_class.new(email:, type: described_class::Types::WORK) }.not_to raise_error
      end
    end

    context "without email" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(email: nil) }
          .to raise_error(ActiveModel::ValidationError, /Email can't be blank/)
      end
    end

    context "with invalid type" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(email:, type: "INVALID") }
          .to raise_error(ActiveModel::ValidationError, /Type is not included in the list/)
      end
    end
  end

  describe "#serialize" do
    context "with only email" do
      subject(:serialized) { described_class.new(email:).serialize }

      it "includes email" do
        expect(serialized[:email]).to eq(email)
      end

      it "omits nil optional fields" do
        expect(serialized).not_to have_key(:type)
      end
    end

    context "with type" do
      subject(:serialized) { described_class.new(email:, type: described_class::Types::HOME).serialize }

      it "includes type" do
        expect(serialized[:type]).to eq(described_class::Types::HOME)
      end
    end
  end
end

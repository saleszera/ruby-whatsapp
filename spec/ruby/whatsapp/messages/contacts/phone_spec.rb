# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Contacts::Phone do
  let(:phone) { Faker::PhoneNumber.cell_phone_in_e164 }

  describe "#initialize" do
    context "with only phone" do
      it "is valid" do
        expect { described_class.new(phone:) }.not_to raise_error
      end
    end

    context "with all fields" do
      it "is valid" do
        expect do
          described_class.new(
            phone:,
            type: described_class::Types::CELL,
            wa_id: Faker::Alphanumeric.alphanumeric(number: 12)
          )
        end.not_to raise_error
      end
    end

    context "without phone" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(phone: nil) }
          .to raise_error(ActiveModel::ValidationError, /Phone can't be blank/)
      end
    end

    context "with invalid type" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(phone:, type: "INVALID") }
          .to raise_error(ActiveModel::ValidationError, /Type is not included in the list/)
      end
    end
  end

  describe "#serialize" do
    context "with only phone" do
      subject(:serialized) { described_class.new(phone:).serialize }

      it "includes phone" do
        expect(serialized[:phone]).to eq(phone)
      end

      it "omits nil optional fields" do
        expect(serialized).not_to have_key(:type)
        expect(serialized).not_to have_key(:wa_id)
      end
    end

    context "with all fields" do
      subject(:serialized) do
        described_class.new(phone:, type: described_class::Types::WORK, wa_id:).serialize
      end

      let(:wa_id) { Faker::Alphanumeric.alphanumeric(number: 12) }

      it "includes all fields" do
        expect(serialized[:phone]).to eq(phone)
        expect(serialized[:type]).to eq(described_class::Types::WORK)
        expect(serialized[:wa_id]).to eq(wa_id)
      end
    end
  end
end

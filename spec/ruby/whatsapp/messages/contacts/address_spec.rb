# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Contacts::Address do
  describe "#initialize" do
    context "with no fields" do
      it "is valid" do
        expect { described_class.new }.not_to raise_error
      end
    end

    context "with all fields" do
      it "is valid" do
        expect do
          described_class.new(
            street: Faker::Address.street_address,
            city: Faker::Address.city,
            state: Faker::Address.state,
            zip: Faker::Address.zip,
            country: Faker::Address.country,
            country_code: Faker::Address.country_code,
            type: described_class::Types::WORK
          )
        end.not_to raise_error
      end
    end

    context "with invalid type" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(type: "INVALID") }
          .to raise_error(ActiveModel::ValidationError, /Type is not included in the list/)
      end
    end
  end

  describe "#serialize" do
    context "with no fields" do
      it "returns an empty hash" do
        expect(described_class.new.serialize).to eq({})
      end
    end

    context "with all fields" do
      subject(:serialized) do
        described_class.new(
          street:,
          city:,
          state:,
          zip:,
          country:,
          country_code:,
          type: described_class::Types::HOME
        ).serialize
      end

      let(:street) { Faker::Address.street_address }
      let(:city) { Faker::Address.city }
      let(:state) { Faker::Address.state }
      let(:zip) { Faker::Address.zip }
      let(:country) { Faker::Address.country }
      let(:country_code) { Faker::Address.country_code }

      it "includes all fields" do
        expect(serialized[:street]).to eq(street)
        expect(serialized[:city]).to eq(city)
        expect(serialized[:state]).to eq(state)
        expect(serialized[:zip]).to eq(zip)
        expect(serialized[:country]).to eq(country)
        expect(serialized[:country_code]).to eq(country_code)
        expect(serialized[:type]).to eq(described_class::Types::HOME)
      end
    end

    context "with only some fields" do
      subject(:serialized) do
        described_class.new(city: Faker::Address.city, country: Faker::Address.country).serialize
      end

      it "omits nil fields" do
        expect(serialized).not_to have_key(:street)
        expect(serialized).not_to have_key(:state)
        expect(serialized).not_to have_key(:zip)
        expect(serialized).not_to have_key(:country_code)
        expect(serialized).not_to have_key(:type)
      end
    end
  end
end

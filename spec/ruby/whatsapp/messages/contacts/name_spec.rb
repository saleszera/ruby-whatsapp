# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Contacts::Name do
  let(:formatted_name) { Faker::Name.name }

  describe "#initialize" do
    context "with only formatted_name" do
      it "is valid" do
        expect { described_class.new(formatted_name:) }.not_to raise_error
      end
    end

    context "with all optional fields" do
      it "is valid" do
        expect do
          described_class.new(
            formatted_name:,
            first_name: Faker::Name.first_name,
            last_name: Faker::Name.last_name,
            middle_name: Faker::Name.middle_name,
            prefix: Faker::Name.prefix,
            suffix: Faker::Name.suffix
          )
        end.not_to raise_error
      end
    end

    context "without formatted_name" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(formatted_name: nil) }
          .to raise_error(ActiveModel::ValidationError, /Formatted name can't be blank/)
      end
    end
  end

  describe "#serialize" do
    context "with only formatted_name" do
      subject(:serialized) { described_class.new(formatted_name:).serialize }

      it "includes formatted_name" do
        expect(serialized[:formatted_name]).to eq(formatted_name)
      end

      it "omits nil optional fields" do
        expect(serialized).not_to have_key(:first_name)
        expect(serialized).not_to have_key(:last_name)
        expect(serialized).not_to have_key(:middle_name)
        expect(serialized).not_to have_key(:prefix)
        expect(serialized).not_to have_key(:suffix)
      end
    end

    context "with all fields" do
      subject(:serialized) do
        described_class.new(
          formatted_name:,
          first_name:,
          last_name:,
          middle_name:,
          prefix:,
          suffix:
        ).serialize
      end

      let(:first_name) { Faker::Name.first_name }
      let(:last_name) { Faker::Name.last_name }
      let(:middle_name) { Faker::Name.middle_name }
      let(:prefix) { Faker::Name.prefix }
      let(:suffix) { Faker::Name.suffix }

      it "includes all fields" do
        expect(serialized[:formatted_name]).to eq(formatted_name)
        expect(serialized[:first_name]).to eq(first_name)
        expect(serialized[:last_name]).to eq(last_name)
        expect(serialized[:middle_name]).to eq(middle_name)
        expect(serialized[:prefix]).to eq(prefix)
        expect(serialized[:suffix]).to eq(suffix)
      end
    end
  end
end

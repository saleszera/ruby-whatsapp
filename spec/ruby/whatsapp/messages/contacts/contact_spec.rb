# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Contacts::Contact do
  let(:name_attrs) { { formatted_name: Faker::Name.name } }

  describe "#initialize" do
    context "with only name" do
      it "is valid" do
        expect { described_class.new(name: name_attrs) }.not_to raise_error
      end
    end

    context "with all optional fields" do
      it "is valid" do
        expect do
          described_class.new(
            name: name_attrs,
            phones: [{ phone: Faker::PhoneNumber.cell_phone_in_e164 }],
            emails: [{ email: Faker::Internet.email }],
            addresses: [{ city: Faker::Address.city, type: "HOME" }],
            org: { company: Faker::Company.name },
            urls: [{ url: Faker::Internet.url }],
            birthday: Faker::Date.birthday(min_age: 18, max_age: 65).strftime("%Y-%m-%d")
          )
        end.not_to raise_error
      end
    end

    context "without name" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(name: { formatted_name: nil }) }
          .to raise_error(ActiveModel::ValidationError)
      end
    end

    context "with pre-built sub-objects" do
      it "is valid when passed Name, Phone, Email, etc. directly" do
        name = Whatsapp::Messages::Contacts::Name.new(formatted_name: Faker::Name.name)
        phone = Whatsapp::Messages::Contacts::Phone.new(phone: Faker::PhoneNumber.cell_phone_in_e164)
        expect { described_class.new(name:, phones: [phone]) }.not_to raise_error
      end
    end
  end

  describe "#serialize" do
    context "with only name" do
      subject(:serialized) { described_class.new(name: name_attrs).serialize }

      it "includes serialized name" do
        expect(serialized[:name]).to eq({ formatted_name: name_attrs[:formatted_name] })
      end

      it "omits empty arrays and nil fields" do
        expect(serialized).not_to have_key(:phones)
        expect(serialized).not_to have_key(:emails)
        expect(serialized).not_to have_key(:addresses)
        expect(serialized).not_to have_key(:org)
        expect(serialized).not_to have_key(:urls)
        expect(serialized).not_to have_key(:birthday)
      end
    end

    context "with phones" do
      subject(:serialized) do
        described_class.new(name: name_attrs, phones: [{ phone: phone_number }]).serialize
      end

      let(:phone_number) { Faker::PhoneNumber.cell_phone_in_e164 }

      it "includes serialized phones" do
        expect(serialized[:phones]).to eq([{ phone: phone_number }])
      end
    end

    context "with org" do
      subject(:serialized) do
        described_class.new(name: name_attrs, org: { company: }).serialize
      end

      let(:company) { Faker::Company.name }

      it "includes serialized org" do
        expect(serialized[:org]).to eq({ company: })
      end
    end

    context "with birthday" do
      subject(:serialized) { described_class.new(name: name_attrs, birthday:).serialize }

      let(:birthday) { Faker::Date.birthday(min_age: 18, max_age: 65).strftime("%Y-%m-%d") }

      it "includes birthday" do
        expect(serialized[:birthday]).to eq(birthday)
      end
    end
  end
end

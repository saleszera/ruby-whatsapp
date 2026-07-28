# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Contacts do
  let(:to) { Faker::PhoneNumber.cell_phone_in_e164 }
  let(:contact_attrs) { { name: { formatted_name: Faker::Name.name } } }

  describe "#initialize" do
    context "with one contact" do
      it "is valid" do
        expect { described_class.new(to:, contacts: [contact_attrs]) }.not_to raise_error
      end
    end

    context "without contacts" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(to:, contacts: []) }
          .to raise_error(ActiveModel::ValidationError, /Contacts can't be blank/)
      end
    end

    context "with more than one contact" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(to:, contacts: [contact_attrs, contact_attrs]) }
          .to raise_error(ActiveModel::ValidationError, /Contacts is too long/)
      end
    end

    context "without to" do
      it "raises ArgumentError" do
        expect { described_class.new(contacts: [contact_attrs]) }
          .to raise_error(ArgumentError, /missing keyword: :?to/)
      end
    end
  end

  describe "#serialize" do
    subject(:serialized) { described_class.new(to:, contacts: [contact_attrs]).serialize }

    it "returns the correct type" do
      expect(serialized[:type]).to eq("contacts")
    end

    it "includes messaging product and recipient type" do
      expect(serialized[:messaging_product]).to eq("whatsapp")
      expect(serialized[:recipient_type]).to eq("individual")
    end

    it "includes the recipient phone number" do
      expect(serialized[:to]).to eq(to)
    end

    it "includes the serialized contacts array" do
      expect(serialized[:contacts]).to be_an(Array)
      expect(serialized[:contacts].first[:name][:formatted_name]).to eq(contact_attrs[:name][:formatted_name])
    end
  end
end

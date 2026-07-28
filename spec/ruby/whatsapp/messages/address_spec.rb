# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Address do
  let(:to) { Faker::PhoneNumber.cell_phone_in_e164 }
  let(:body) { Faker::Lorem.sentence }

  describe "#initialize" do
    context "with required fields (India)" do
      it "is valid" do
        expect { described_class.new(to:, body:, country: described_class::Countries::IN) }.not_to raise_error
      end
    end

    context "with required fields (Singapore)" do
      it "is valid" do
        expect { described_class.new(to:, body:, country: described_class::Countries::SG) }.not_to raise_error
      end
    end

    context "with all optional fields" do
      it "is valid" do
        expect do
          described_class.new(
            to:,
            body:,
            country: described_class::Countries::IN,
            footer: Faker::Lorem.sentence,
            values: {
              name: Faker::Name.name,
              phone_number: Faker::PhoneNumber.cell_phone_in_e164,
              pin_code: Faker::Address.zip_code,
            },
            saved_addresses: [
              {
                id: Faker::Alphanumeric.alphanumeric(number: 8),
                name: Faker::Name.name,
                pin_code: Faker::Address.zip_code,
                address: Faker::Address.street_address,
                city: Faker::Address.city,
                state: Faker::Address.state,
              },
            ]
          )
        end.not_to raise_error
      end
    end

    context "without body" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(to:, body: nil, country: described_class::Countries::IN) }
          .to raise_error(ActiveModel::ValidationError, /Body can't be blank/)
      end
    end

    context "without country" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(to:, body:, country: nil) }
          .to raise_error(ActiveModel::ValidationError, /Country can't be blank/)
      end
    end

    context "with unsupported country" do
      it "raises ActiveModel::ValidationError" do
        expect { described_class.new(to:, body:, country: "US") }
          .to raise_error(ActiveModel::ValidationError, /Country is not included in the list/)
      end
    end

    context "without to" do
      it "raises ArgumentError" do
        expect { described_class.new(body:, country: described_class::Countries::IN) }
          .to raise_error(ArgumentError, /missing keyword: :?to/)
      end
    end
  end

  describe "#serialize" do
    subject(:serialized) { described_class.new(to:, body:, country: described_class::Countries::IN).serialize }

    it "sets the outer type to interactive" do
      expect(serialized[:type]).to eq("interactive")
    end

    it "includes messaging product and recipient type" do
      expect(serialized[:messaging_product]).to eq("whatsapp")
      expect(serialized[:recipient_type]).to eq("individual")
    end

    it "includes the recipient phone number" do
      expect(serialized[:to]).to eq(to)
    end

    it "sets the interactive type to address_message" do
      expect(serialized[:interactive][:type]).to eq("address_message")
    end

    it "includes the body text" do
      expect(serialized[:interactive][:body][:text]).to eq(body)
    end

    it "sets the action name to address_message" do
      expect(serialized[:interactive][:action][:name]).to eq("address_message")
    end

    it "includes the country in action parameters" do
      expect(serialized[:interactive][:action][:parameters][:country]).to eq(described_class::Countries::IN)
    end

    it "omits footer when not provided" do
      expect(serialized[:interactive]).not_to have_key(:footer)
    end

    context "with footer" do
      subject(:serialized) do
        described_class.new(to:, body:, country: described_class::Countries::IN, footer: footer_text).serialize
      end

      let(:footer_text) { Faker::Lorem.sentence }

      it "includes the footer text" do
        expect(serialized[:interactive][:footer][:text]).to eq(footer_text)
      end
    end

    context "with values" do
      subject(:serialized) do
        described_class.new(to:, body:, country: described_class::Countries::IN, values:).serialize
      end

      let(:values) { { name: Faker::Name.name, pin_code: Faker::Address.zip_code } }

      it "includes values in action parameters" do
        expect(serialized[:interactive][:action][:parameters][:values]).to eq(values)
      end
    end

    context "with saved_addresses" do
      subject(:serialized) do
        described_class.new(to:, body:, country: described_class::Countries::IN, saved_addresses:).serialize
      end

      let(:saved_addresses) do
        [{ id: Faker::Alphanumeric.alphanumeric(number: 8), name: Faker::Name.name }]
      end

      it "includes saved_addresses in action parameters" do
        expect(serialized[:interactive][:action][:parameters][:saved_addresses]).to eq(saved_addresses)
      end
    end

    context "without values or saved_addresses" do
      it "omits both from action parameters" do
        expect(serialized[:interactive][:action][:parameters]).not_to have_key(:values)
        expect(serialized[:interactive][:action][:parameters]).not_to have_key(:saved_addresses)
      end
    end
  end
end

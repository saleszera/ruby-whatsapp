# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Button::PhoneNumber do
  describe "#serialize" do
    it "emits the wire type, label and number" do
      expect(described_class.new(text: "Call", phone_number: "15550051310").serialize)
        .to eq(type: "PHONE_NUMBER", text: "Call", phone_number: "15550051310")
    end
  end

  describe "validations" do
    it "requires text" do
      expect { described_class.new(text: nil, phone_number: "15550051310") }
        .to raise_error(ActiveModel::ValidationError, /Text can't be blank/)
    end

    it "rejects text over 25 characters" do
      expect { described_class.new(text: "a" * 26, phone_number: "15550051310") }
        .to raise_error(ActiveModel::ValidationError, /Text is too long/)
    end

    it "requires a phone number" do
      expect { described_class.new(text: "Call", phone_number: nil) }
        .to raise_error(ActiveModel::ValidationError, /Phone number can't be blank/)
    end

    it "rejects a phone number over 20 characters" do
      expect { described_class.new(text: "Call", phone_number: "1" * 21) }
        .to raise_error(ActiveModel::ValidationError, /Phone number is too long/)
    end
  end
end

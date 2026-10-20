# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Base do
  describe "#initialize" do
    it "accepts a phone number alone" do
      message = described_class.new(to: "+15551234567")

      expect(message).to be_valid
      expect(message.to).to eq("+15551234567")
      expect(message.recipient).to be_nil
    end

    it "accepts a BSUID alone" do
      message = described_class.new(recipient: "US.13491208655302741918")

      expect(message).to be_valid
      expect(message.to).to be_nil
      expect(message.recipient).to eq("US.13491208655302741918")
    end

    it "accepts a parent BSUID as the recipient" do
      message = described_class.new(recipient: "US.ENT.11815799212886844830")

      expect(message).to be_valid
      expect(message.recipient).to eq("US.ENT.11815799212886844830")
    end

    it "accepts both, since Meta lets the phone number take precedence server-side" do
      message = described_class.new(to: "+15551234567", recipient: "US.13491208655302741918")

      expect(message).to be_valid
      expect(message.to).to eq("+15551234567")
      expect(message.recipient).to eq("US.13491208655302741918")
    end

    it "is invalid with neither identifier" do
      message = described_class.new

      expect(message).not_to be_valid
      expect(message.errors[:base]).to include("at least one of to or recipient must be provided")
    end

    it "rejects a blank phone number, as Meta does" do
      message = described_class.new(to: "")

      expect(message).not_to be_valid
      expect(message.errors[:to]).to include("can't be blank")
    end

    it "rejects a blank recipient" do
      message = described_class.new(recipient: "")

      expect(message).not_to be_valid
      expect(message.errors[:recipient]).to include("can't be blank")
    end

    it "reports the blank recipient rather than the missing-identifier error when one is given blank" do
      message = described_class.new(recipient: "")

      expect(message).not_to be_valid
      expect(message.errors[:base]).to be_empty
      expect(message.errors[:recipient]).to include("can't be blank")
    end
  end

  describe "#serialize" do
    it "is abstract" do
      expect { described_class.new(to: "+15551234567").serialize }
        .to raise_error(NotImplementedError, /Subclasses must implement the serialize method/)
    end
  end

  describe "#envelope" do
    subject(:envelope) { message.send(:envelope, type: "text", text: { body: "Hi" }) }

    context "with a phone number alone" do
      let(:message) { described_class.new(to: "+15551234567") }

      it "sends to and omits recipient entirely, rather than sending it as null" do
        expect(envelope).to eq(
          messaging_product: "whatsapp", recipient_type: "individual",
          to: "+15551234567", type: "text", text: { body: "Hi" }
        )
        expect(envelope).not_to have_key(:recipient)
      end
    end

    context "with a BSUID alone" do
      let(:message) { described_class.new(recipient: "US.13491208655302741918") }

      it "sends recipient and omits to entirely" do
        expect(envelope).to eq(
          messaging_product: "whatsapp", recipient_type: "individual",
          recipient: "US.13491208655302741918", type: "text", text: { body: "Hi" }
        )
        expect(envelope).not_to have_key(:to)
      end
    end

    context "with both" do
      let(:message) { described_class.new(to: "+15551234567", recipient: "US.13491208655302741918") }

      it "sends both, keeping to ahead of recipient" do
        expect(envelope[:to]).to eq("+15551234567")
        expect(envelope[:recipient]).to eq("US.13491208655302741918")
        expect(envelope.keys).to eq(%i[messaging_product recipient_type to recipient type text])
      end
    end
  end

  describe "RECIPIENT_ATTRIBUTES" do
    it "is frozen" do
      expect(described_class::RECIPIENT_ATTRIBUTES).to be_frozen
    end

    it "names the two ways to address a message" do
      expect(described_class::RECIPIENT_ATTRIBUTES).to eq(%i[to recipient])
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Button do
  describe ".build" do
    it "resolves every registered type to its class" do
      expect(described_class.build(type: :quick_reply, text: "Stop")).to be_a(described_class::QuickReply)
      expect(described_class.build(type: :url, text: "Shop", url: "https://x.test"))
        .to be_a(described_class::Url)
      expect(described_class.build(type: :phone_number, text: "Call", phone_number: "15550051310"))
        .to be_a(described_class::PhoneNumber)
      expect(described_class.build(type: :copy_code, example: "250FF")).to be_a(described_class::CopyCode)
      expect(described_class.build(type: :otp, otp_type: "COPY_CODE")).to be_a(described_class::Otp)
    end

    it "accepts Meta's uppercase wire casing" do
      expect(described_class.build(type: "QUICK_REPLY", text: "Stop")).to be_a(described_class::QuickReply)
    end

    it "accepts a string type" do
      expect(described_class.build(type: "quick_reply", text: "Stop")).to be_a(described_class::QuickReply)
    end

    it "raises for an unknown type" do
      expect { described_class.build(type: :telepathy, text: "Think") }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /Unknown button type/)
    end

    it "never resolves an arbitrary constant" do
      expect { described_class.build(type: "Object") }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /Unknown button type/)
      expect { described_class.build(type: "Kernel") }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /Unknown button type/)
    end

    it "lists the known types in the error message" do
      expect { described_class.build(type: :nope) }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /quick_reply/)
    end
  end

  describe ".serialize" do
    it "builds and serializes in one step" do
      expect(described_class.serialize(type: :quick_reply, text: "Stop Promos"))
        .to eq(type: "QUICK_REPLY", text: "Stop Promos")
    end
  end

  describe "TYPES" do
    it "is frozen so the registry cannot be mutated at runtime" do
      expect(described_class::TYPES).to be_frozen
    end
  end
end

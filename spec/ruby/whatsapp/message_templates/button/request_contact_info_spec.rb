# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Button::RequestContactInfo do
  describe "#serialize" do
    it "sends the type alone, since the button carries nothing else" do
      expect(described_class.new.serialize).to eq(type: "REQUEST_CONTACT_INFO")
    end

    it "forwards Meta's own label when a caller mirrors its example payload" do
      expect(described_class.new(text: "Share Contact Info").serialize)
        .to eq(type: "REQUEST_CONTACT_INFO", text: "Share Contact Info")
    end
  end

  describe "validation" do
    it "accepts being given no text at all" do
      expect { described_class.new }.not_to raise_error
    end

    it "rejects any label but Meta's, explaining why" do
      expect { described_class.new(text: "Share your number") }
        .to raise_error(ActiveModel::ValidationError, /must be exactly "Share Contact Info" if given/)
    end

    it "rejects a blank label" do
      expect { described_class.new(text: "") }
        .to raise_error(ActiveModel::ValidationError, /must be exactly "Share Contact Info" if given/)
    end
  end

  describe "#api_type" do
    it "reports the uppercase wire type" do
      expect(described_class.new.api_type).to eq("REQUEST_CONTACT_INFO")
    end
  end

  describe ".serialize via the registry" do
    it "builds and serializes from Meta's uppercase type name" do
      expect(Whatsapp::MessageTemplates::Button.serialize(type: "REQUEST_CONTACT_INFO"))
        .to eq(type: "REQUEST_CONTACT_INFO")
    end

    it "builds from the snake_case registry key too" do
      expect(Whatsapp::MessageTemplates::Button.build(type: :request_contact_info))
        .to be_a(described_class)
    end
  end
end

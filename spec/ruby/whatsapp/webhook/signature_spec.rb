# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Signature do
  let(:payload) { '{"object":"whatsapp_business_account","entry":[]}' }

  def signature_for(payload, secret)
    "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', secret, payload)}"
  end

  describe ".valid?" do
    it "returns true when the header matches the HMAC of the payload and configured app_secret" do
      Whatsapp.configuration.app_secret = "MY_SECRET"

      expect(described_class.valid?(payload:, header: signature_for(payload, "MY_SECRET"))).to be(true)
    end

    it "returns false when the header does not match" do
      Whatsapp.configuration.app_secret = "MY_SECRET"

      expect(described_class.valid?(payload:, header: signature_for(payload, "WRONG_SECRET"))).to be(false)
    end

    it "returns false when the header is missing" do
      Whatsapp.configuration.app_secret = "MY_SECRET"

      expect(described_class.valid?(payload:, header: nil)).to be(false)
    end

    it "returns false when no app_secret is configured" do
      Whatsapp.configuration.app_secret = nil

      expect(described_class.valid?(payload:, header: signature_for(payload, "MY_SECRET"))).to be(false)
    end

    it "returns false when the payload is nil, without raising" do
      Whatsapp.configuration.app_secret = "MY_SECRET"

      result = nil
      expect { result = described_class.valid?(payload: nil, header: signature_for("", "MY_SECRET")) }
        .not_to raise_error
      expect(result).to be(false)
    end

    it "accepts an explicit app_secret override, ignoring global configuration" do
      Whatsapp.configuration.app_secret = "GLOBAL_SECRET"

      expect(
        described_class.valid?(payload:, header: signature_for(payload, "ACCOUNT_SECRET"), app_secret: "ACCOUNT_SECRET")
      ).to be(true)
    end
  end
end

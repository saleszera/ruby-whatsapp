# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Verification do
  describe ".call" do
    it "returns the hub.challenge when the mode and token match" do
      Whatsapp.configuration.verify_token = "MY_TOKEN"

      challenge = described_class.call(
        params: { "hub.mode" => "subscribe", "hub.verify_token" => "MY_TOKEN", "hub.challenge" => "12345" }
      )

      expect(challenge).to eq("12345")
    end

    it "returns nil when hub.mode is not subscribe" do
      Whatsapp.configuration.verify_token = "MY_TOKEN"

      challenge = described_class.call(
        params: { "hub.mode" => "unsubscribe", "hub.verify_token" => "MY_TOKEN", "hub.challenge" => "12345" }
      )

      expect(challenge).to be_nil
    end

    it "returns nil when the verify_token does not match" do
      Whatsapp.configuration.verify_token = "MY_TOKEN"

      challenge = described_class.call(
        params: { "hub.mode" => "subscribe", "hub.verify_token" => "WRONG", "hub.challenge" => "12345" }
      )

      expect(challenge).to be_nil
    end

    it "returns nil when no verify_token is configured" do
      Whatsapp.configuration.verify_token = nil

      challenge = described_class.call(
        params: { "hub.mode" => "subscribe", "hub.verify_token" => "", "hub.challenge" => "12345" }
      )

      expect(challenge).to be_nil
    end

    it "accepts an explicit verify_token override, ignoring global configuration" do
      Whatsapp.configuration.verify_token = "GLOBAL_TOKEN"

      challenge = described_class.call(
        params: { "hub.mode" => "subscribe", "hub.verify_token" => "ACCOUNT_TOKEN", "hub.challenge" => "12345" },
        verify_token: "ACCOUNT_TOKEN"
      )

      expect(challenge).to eq("12345")
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::RequestCode do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/request_code" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "#serialize" do
    it "emits both documented parameters" do
      result = described_class.new(code_method: "SMS", language: "en_US").serialize

      expect(result).to eq(code_method: "SMS", language: "en_US")
    end

    it "normalizes a lowercase or symbol code_method to uppercase" do
      expect(described_class.new(code_method: :sms, language: "en_US").serialize[:code_method]).to eq("SMS")
      expect(described_class.new(code_method: "voice", language: "en_US").serialize[:code_method]).to eq("VOICE")
    end
  end

  describe "code_method validation" do
    it "rejects an unsupported code_method" do
      expect { described_class.new(code_method: "EMAIL", language: "en_US") }
        .to raise_error(ActiveModel::ValidationError, /Code method is not included in the list/)
    end

    it "rejects a nil code_method" do
      expect { described_class.new(code_method: nil, language: "en_US") }
        .to raise_error(ActiveModel::ValidationError, /Code method/)
    end

    it "accepts SMS and VOICE" do
      expect { described_class.new(code_method: "SMS", language: "en_US") }.not_to raise_error
      expect { described_class.new(code_method: "VOICE", language: "en_US") }.not_to raise_error
    end
  end

  describe "language validation" do
    it "rejects a nil language" do
      expect { described_class.new(code_method: "SMS", language: nil) }
        .to raise_error(ActiveModel::ValidationError, /Language can't be blank/)
    end

    it "rejects a blank language" do
      expect { described_class.new(code_method: "SMS", language: "") }
        .to raise_error(ActiveModel::ValidationError, /Language can't be blank/)
    end
  end

  describe ".call" do
    it "posts to the phone number's request_code edge and returns a response" do
      stub = stub_request(:post, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" }, body: { code_method: "SMS", language: "en_US" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      result = described_class.call(code_method: "SMS", language: "en_US")

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Response)
      expect(result.success).to be(true)
      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER/request_code")
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(code_method: "SMS", language: "en_US", client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(code_method: "SMS", language: "en_US", client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id/)
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 400, headers: json, body: { error: { message: "Invalid parameter", code: 100 } }.to_json
      )

      expect { described_class.call(code_method: "SMS", language: "en_US") }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error,
          /Failed to request verification code.*Invalid parameter/)
    end

    it "reports an unsuccessful request" do
      stub_request(:post, edge).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(described_class.call(code_method: "SMS", language: "en_US").success).to be(false)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:post, edge).to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(described_class.call(code_method: "SMS", language: "en_US").success).to be(true)
    end

    it "raises a validation error before making any request for an invalid code_method" do
      expect { described_class.call(code_method: "EMAIL", language: "en_US") }
        .to raise_error(ActiveModel::ValidationError)
      expect(a_request(:post, edge)).not_to have_been_made
    end
  end
end

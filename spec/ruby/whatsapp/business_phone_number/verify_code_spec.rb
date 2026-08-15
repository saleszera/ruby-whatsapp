# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::VerifyCode do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/verify_code" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "#serialize" do
    it "emits the documented payload" do
      expect(described_class.new(code: "123456").serialize).to eq(code: "123456")
    end

    it "coerces an integer code to its string form" do
      expect(described_class.new(code: 123_456).serialize[:code]).to eq("123456")
    end
  end

  describe "code validation" do
    it "rejects a nil code" do
      expect { described_class.new(code: nil) }
        .to raise_error(ActiveModel::ValidationError, /Code can't be blank/)
    end

    it "rejects a blank code" do
      expect { described_class.new(code: "") }
        .to raise_error(ActiveModel::ValidationError, /Code can't be blank/)
    end

    it "accepts any non-blank string, since Meta documents no format for it" do
      expect { described_class.new(code: "123456") }.not_to raise_error
      expect { described_class.new(code: "12345") }.not_to raise_error
      expect { described_class.new(code: "ABC-123") }.not_to raise_error
    end
  end

  describe "#inspect" do
    it "redacts the code" do
      result = described_class.new(code: "123456").inspect

      expect(result).not_to include("123456")
      expect(result).to include("code=[REDACTED]")
    end
  end

  describe ".call" do
    it "posts to the phone number's verify_code edge and returns a response" do
      stub = stub_request(:post, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" }, body: { code: "123456" })
        .to_return(status: 200, headers: json, body: { success: true, id: "106540352242922" }.to_json)

      result = described_class.call(code: "123456")

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Response)
      expect(result.success).to be(true)
      expect(result.id).to eq("106540352242922")
      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER/verify_code")
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(code: "123456", client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(code: "123456", client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id/)
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 422, headers: json,
        body: { error: { message: "The verification code is invalid or has expired", code: 100 } }.to_json
      )

      expect { described_class.call(code: "123456") }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /Failed to verify code.*invalid or has expired/)
    end

    it "reports an unsuccessful verification" do
      stub_request(:post, edge).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(described_class.call(code: "123456").success).to be(false)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:post, edge).to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(described_class.call(code: "123456").success).to be(true)
    end

    it "raises a validation error before making any request for a blank code" do
      expect { described_class.call(code: "") }.to raise_error(ActiveModel::ValidationError)
      expect(a_request(:post, edge)).not_to have_been_made
    end
  end
end

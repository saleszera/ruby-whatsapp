# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Deregister do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/deregister" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "#serialize" do
    it "returns an empty payload, as Meta documents no parameters" do
      expect(described_class.new.serialize).to eq({})
    end
  end

  describe ".call" do
    it "posts to the phone number's deregister edge with an empty body and returns a response" do
      stub = stub_request(:post, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" }, body: {})
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Response)
      expect(result.success).to be(true)
      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER/deregister")
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id/)
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 404, headers: json, body: { error: { message: "Phone number not found", code: 803 } }.to_json
      )

      expect { described_class.call }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error,
          /Failed to deregister business phone number.*Phone number not found/)
    end

    it "reports an unsuccessful deregistration" do
      stub_request(:post, edge).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(described_class.call.success).to be(false)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:post, edge).to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(described_class.call.success).to be(true)
    end
  end
end

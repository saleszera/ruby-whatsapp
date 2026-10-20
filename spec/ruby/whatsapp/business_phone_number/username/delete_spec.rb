# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Username::Delete do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/username" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe ".call" do
    it "deletes the username edge and reports success" do
      stub = stub_request(:delete, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Response)
      expect(result.success).to be(true)
      expect(stub).to have_been_requested
    end

    it "reports a refusal rather than treating it as success" do
      stub_request(:delete, edge).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(described_class.call.success).to be(false)
    end

    it "addresses an explicitly passed client's phone number" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:delete, "https://graph.facebook.com/v24.0/OTHER/username")
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured, without making a request" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id is required for the username edge/)
      expect(a_request(:delete, edge)).not_to have_been_made
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:delete, edge).to_return(status: 403, headers: json, body: {
        error: { message: "Application does not have permission for this action", code: 10 },
      }.to_json)

      expect { described_class.call }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /Failed to delete business username/)
    end
  end
end

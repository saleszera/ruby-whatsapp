# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Username::Get do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/username" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe ".call" do
    it "gets the phone number's username edge and returns the details" do
      stub = stub_request(:get, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, headers: json, body: { username: "jaspersmarket", status: "approved" }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Username::Details)
      expect(result.username).to eq("jaspersmarket")
      expect(result).to be_approved
      expect(stub).to have_been_requested
    end

    it "returns details with no username when the number has none set" do
      stub_request(:get, edge).to_return(status: 200, headers: json, body: { status: "reserved" }.to_json)

      result = described_class.call

      expect(result.username).to be_nil
      expect(result).to be_reserved
    end

    it "addresses an explicitly passed client's phone number" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:get, "https://graph.facebook.com/v24.0/OTHER/username")
        .to_return(status: 200, headers: json, body: { status: "approved" }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured, without making a request" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id is required for the username edge/)
      expect(a_request(:get, edge)).not_to have_been_made
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:get, edge).to_return(status: 400, headers: json, body: {
        error: { message: "Invalid ID", code: 33 },
      }.to_json)

      expect { described_class.call }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /Failed to get business username.*Invalid ID/)
    end
  end
end

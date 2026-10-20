# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Username::Suggest do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/username_suggestions" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe ".call" do
    it "gets the suggestions edge, not the username one" do
      stub = stub_request(:get, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, headers: json, body: {
          data: [{ username_suggestions: %w[jaspersmarket jaspers_market] }],
        }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Username::Suggestions)
      expect(result.to_a).to eq(%w[jaspersmarket jaspers_market])
      expect(stub).to have_been_requested
      expect(a_request(:get, "https://graph.facebook.com/v24.0/PHONE_ID/username")).not_to have_been_made
    end

    it "returns an empty list when Meta has reserved nothing" do
      stub_request(:get, edge).to_return(status: 200, headers: json, body: { data: [] }.to_json)

      expect(described_class.call.to_a).to eq([])
    end

    it "addresses an explicitly passed client's phone number" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:get, "https://graph.facebook.com/v24.0/OTHER/username_suggestions")
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured, naming the suggestions edge" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:) }
        .to raise_error(
          Whatsapp::BusinessPhoneNumber::Error,
          /phone_id is required for the username_suggestions edge/
        )
      expect(a_request(:get, edge)).not_to have_been_made
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:get, edge).to_return(status: 400, headers: json, body: {
        error: { message: "Invalid ID", code: 33 },
      }.to_json)

      expect { described_class.call }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /Failed to get username suggestions/)
    end
  end
end

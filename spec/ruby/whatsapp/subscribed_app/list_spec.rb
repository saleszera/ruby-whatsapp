# frozen_string_literal: true

RSpec.describe Whatsapp::SubscribedApp::List do
  let(:edge) { "https://graph.facebook.com/v24.0/WABA_ID/subscribed_apps" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe ".call" do
    it "gets the WABA edge and returns a collection" do
      stub = stub_request(:get, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, headers: json, body: {
          data: [{ whatsapp_business_api_data: { id: "123", name: "My App", link: "https://example.com/app" } }],
        }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::SubscribedApp::Response::Collection)
      expect(result.map(&:name)).to eq(["My App"])
      expect(stub).to have_been_requested
    end

    it "joins a fields array into a comma separated query parameter" do
      stub = stub_request(:get, edge)
        .with(query: { fields: "id,name,link" })
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call(fields: %w[id name link])

      expect(stub).to have_been_requested
    end

    it "sends no fields parameter by default" do
      stub = stub_request(:get, edge)
        .with { |request| !request.uri.query.to_s.include?("fields") }
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call

      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(waba_id: "OTHER")
      stub = stub_request(:get, "https://graph.facebook.com/v24.0/OTHER/subscribed_apps")
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "raises when no waba_id is configured" do
      client = Whatsapp::Client.new(waba_id: nil)

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::SubscribedApp::Error, /waba_id/)
    end

    it "raises a SubscribedApp::Error when the API rejects the request" do
      stub_request(:get, edge).to_return(
        status: 403, headers: json, body: { error: { message: "Permissions error", code: 200 } }.to_json
      )

      expect { described_class.call }
        .to raise_error(Whatsapp::SubscribedApp::Error, /Failed to list subscribed apps.*Permissions error/)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:get, edge).to_return(status: 200, headers: js, body: { data: [] }.to_json)

      expect(described_class.call.data).to eq([])
    end
  end
end

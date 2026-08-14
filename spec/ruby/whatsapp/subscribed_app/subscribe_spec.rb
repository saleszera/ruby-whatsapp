# frozen_string_literal: true

RSpec.describe Whatsapp::SubscribedApp::Subscribe do
  let(:edge) { "https://graph.facebook.com/v24.0/WABA_ID/subscribed_apps" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe ".call" do
    it "posts to the WABA edge with an empty body and returns a subscription" do
      stub = stub_request(:post, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" }, body: {})
        .to_return(status: 200, headers: json, body: {
          success: true,
          data: [{ whatsapp_business_api_data: { id: "123", name: "My App", link: "https://example.com/app" } }],
        }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::SubscribedApp::Response::Subscription)
      expect(result.success).to be(true)
      expect(result.map(&:name)).to eq(["My App"])
      expect(stub).to have_been_requested
    end

    it "posts the override callback uri and verify token when given" do
      stub = stub_request(:post, edge)
        .with(body: { override_callback_uri: "https://example.com/webhooks", verify_token: "SECRET" })
        .to_return(status: 200, headers: json, body: { success: true, data: [] }.to_json)

      described_class.call(override_callback_uri: "https://example.com/webhooks", verify_token: "SECRET")

      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(waba_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER/subscribed_apps")
        .to_return(status: 200, headers: json, body: { success: true, data: [] }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "raises when no waba_id is configured" do
      client = Whatsapp::Client.new(waba_id: nil)

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::SubscribedApp::Error, /waba_id/)
    end

    it "raises a SubscribedApp::Error when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 400, headers: json, body: { error: { message: "Invalid parameter", code: 100 } }.to_json
      )

      expect { described_class.call }
        .to raise_error(Whatsapp::SubscribedApp::Error, /Failed to subscribe app.*Invalid parameter/)
    end

    it "reports an unsuccessful subscription" do
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

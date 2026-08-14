# frozen_string_literal: true

RSpec.describe Whatsapp::SubscribedApp::Unsubscribe do
  let(:edge) { "https://graph.facebook.com/v24.0/WABA_ID/subscribed_apps" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe ".call" do
    it "deletes the WABA edge and returns an unsubscription" do
      stub = stub_request(:delete, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      result = described_class.call

      expect(result).to be_a(Whatsapp::SubscribedApp::Response::Unsubscription)
      expect(result.success).to be(true)
      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(waba_id: "OTHER")
      stub = stub_request(:delete, "https://graph.facebook.com/v24.0/OTHER/subscribed_apps")
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(client:)

      expect(stub).to have_been_requested
    end

    it "raises when no waba_id is configured" do
      client = Whatsapp::Client.new(waba_id: nil)

      expect { described_class.call(client:) }
        .to raise_error(Whatsapp::SubscribedApp::Error, /waba_id/)
    end

    it "raises a SubscribedApp::Error when the API rejects the request" do
      stub_request(:delete, edge).to_return(
        status: 404, headers: json, body: { error: { message: "WABA not found", code: 803 } }.to_json
      )

      expect { described_class.call }
        .to raise_error(Whatsapp::SubscribedApp::Error, /Failed to unsubscribe app.*WABA not found/)
    end

    it "reports an unsuccessful unsubscription" do
      stub_request(:delete, edge).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(described_class.call.success).to be(false)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:delete, edge).to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(described_class.call.success).to be(true)
    end
  end
end

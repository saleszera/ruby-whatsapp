# frozen_string_literal: true

RSpec.describe Whatsapp::Client do
  subject(:client) { described_class.new }

  describe "#connection" do
    it "sets the Authorization bearer header from the api_key" do
      auth = client.connection.default_options.headers["Authorization"]
      expect(auth).to eq("Bearer TEST_TOKEN")
    end

    it "uses the origin as the persistent base (version is NOT baked in)" do
      expect(client.connection.default_options.persistent).to eq("https://graph.facebook.com")
    end

    it "applies a default timeout" do
      expect(client.connection.default_options.timeout_options).not_to be_empty
    end

    it "omits the auth header when no api_key is configured" do
      client = described_class.new(api_key: nil)
      expect(client.connection.default_options.headers["Authorization"]).to be_nil
    end
  end

  describe "#path_for" do
    it "prefixes the API version for resource paths" do
      expect(client.path_for("PHONE_ID", "messages")).to eq("/v24.0/PHONE_ID/messages")
    end

    it "prefixes the API version for media id paths" do
      expect(client.path_for("MEDIA_ID")).to eq("/v24.0/MEDIA_ID")
    end
  end

  describe "defaults" do
    it "reads api_key and phone_id from the global configuration" do
      expect(client.api_key).to eq("TEST_TOKEN")
      expect(client.phone_id).to eq("PHONE_ID")
    end

    it "reads waba_id from the global configuration" do
      expect(client.waba_id).to eq("WABA_ID")
    end

    it "allows waba_id to be overridden per client" do
      expect(described_class.new(waba_id: "OTHER_WABA").waba_id).to eq("OTHER_WABA")
    end
  end
end

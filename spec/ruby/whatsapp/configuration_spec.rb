# frozen_string_literal: true

RSpec.describe Whatsapp::Configuration do
  describe "#initialize" do
    it "defaults host and version" do
      config = described_class.new

      expect(config.host).to eq(Whatsapp::Configuration::Defaults::HOST)
      expect(config.version).to eq(Whatsapp::Configuration::Defaults::VERSION)
    end

    it "defaults verify_token and app_secret to nil" do
      config = described_class.new

      expect(config.verify_token).to be_nil
      expect(config.app_secret).to be_nil
    end

    it "accepts verify_token and app_secret" do
      config = described_class.new(verify_token: "TOKEN", app_secret: "SECRET")

      expect(config.verify_token).to eq("TOKEN")
      expect(config.app_secret).to eq("SECRET")
    end
  end

  describe "#inspect" do
    it "redacts api_key and app_secret but not verify_token" do
      config = described_class.new(api_key: "API_KEY", app_secret: "SECRET", verify_token: "TOKEN")

      expect(config.inspect).to include("api_key=[REDACTED]")
      expect(config.inspect).to include("app_secret=[REDACTED]")
      expect(config.inspect).to include("verify_token=\"TOKEN\"")
      expect(config.inspect).not_to include("API_KEY")
      expect(config.inspect).not_to include("SECRET")
    end

    it "shows nil for unset api_key and app_secret" do
      config = described_class.new

      expect(config.inspect).to include("api_key=nil")
      expect(config.inspect).to include("app_secret=nil")
    end
  end
end

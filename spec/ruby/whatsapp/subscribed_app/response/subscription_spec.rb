# frozen_string_literal: true

RSpec.describe Whatsapp::SubscribedApp::Response::Subscription do
  let(:payload) do
    {
      "success" => true,
      "data" => [
        { "whatsapp_business_api_data" => { "id" => "1", "name" => "App One", "link" => "https://example.com/1" } },
      ],
    }
  end

  describe ".deserialize" do
    it "reads the success flag and types the data as Apps" do
      result = described_class.deserialize(payload)

      expect(result.success).to be(true)
      expect(result.data.map(&:name)).to eq(["App One"])
      expect(result.data).to all(be_a(Whatsapp::SubscribedApp::Response::App))
    end

    it "treats anything other than true as unsuccessful" do
      expect(described_class.deserialize("success" => "true").success).to be(false)
      expect(described_class.deserialize({}).success).to be(false)
    end

    it "tolerates a response with no data" do
      result = described_class.deserialize("success" => true)

      expect(result.data).to eq([])
    end

    it "tolerates a nil payload" do
      result = described_class.deserialize(nil)

      expect(result.success).to be(false)
      expect(result.data).to eq([])
    end
  end

  describe "enumerability" do
    it "iterates the apps directly" do
      result = described_class.deserialize(payload)

      expect(result.map(&:id)).to eq(%w[1])
    end
  end
end

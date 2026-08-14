# frozen_string_literal: true

RSpec.describe Whatsapp::SubscribedApp::Response::Collection do
  let(:payload) do
    {
      "data" => [
        { "whatsapp_business_api_data" => { "id" => "1", "name" => "App One", "link" => "https://example.com/1" } },
        { "whatsapp_business_api_data" => { "id" => "2", "name" => "App Two", "link" => "https://example.com/2" } },
      ],
    }
  end

  describe ".deserialize" do
    it "types each element of data as an App" do
      collection = described_class.deserialize(payload)

      expect(collection.data.map(&:name)).to eq(["App One", "App Two"])
      expect(collection.data).to all(be_a(Whatsapp::SubscribedApp::Response::App))
    end

    it "tolerates a response with no data" do
      collection = described_class.deserialize({})

      expect(collection.data).to eq([])
    end

    it "tolerates a nil payload" do
      expect(described_class.deserialize(nil).data).to eq([])
    end
  end

  describe "enumerability" do
    it "iterates the apps directly" do
      collection = described_class.deserialize(payload)

      expect(collection.map(&:id)).to eq(%w[1 2])
      expect(collection.count).to eq(2)
    end
  end
end

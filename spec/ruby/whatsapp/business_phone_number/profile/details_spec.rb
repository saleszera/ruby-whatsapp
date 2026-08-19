# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Profile::Details do
  let(:profile) do
    {
      "messaging_product" => "whatsapp",
      "about" => "Open daily 9-5",
      "address" => "1 Infinite Loop, Cupertino, CA",
      "description" => "We sell excellent widgets.",
      "email" => "hello@acme.test",
      "profile_picture_url" => "https://cdn.acme.test/logo.png",
      "websites" => ["https://acme.test", "https://shop.acme.test"],
      "vertical" => "RETAIL",
    }
  end

  let(:payload) { { "data" => [profile] } }

  describe ".deserialize" do
    it "maps every documented field out of the data array" do
      expect(described_class.deserialize(payload)).to have_attributes(
        messaging_product: "whatsapp",
        about: "Open daily 9-5",
        address: "1 Infinite Loop, Cupertino, CA",
        description: "We sell excellent widgets.",
        email: "hello@acme.test",
        profile_picture_url: "https://cdn.acme.test/logo.png",
        websites: ["https://acme.test", "https://shop.acme.test"],
        vertical: "RETAIL"
      )
    end

    it "reads the business_profile nesting Meta's reference documents" do
      nested = { "data" => [{ "business_profile" => profile }] }

      expect(described_class.deserialize(nested)).to have_attributes(about: "Open daily 9-5", vertical: "RETAIL")
    end

    it "reads only the first entry, since one number has one profile" do
      two = { "data" => [profile, { "about" => "Someone else" }] }

      expect(described_class.deserialize(two).about).to eq("Open daily 9-5")
    end

    it "tolerates a nil payload" do
      expect(described_class.deserialize(nil)).to have_attributes(about: nil, vertical: nil, websites: nil)
    end

    it "tolerates a payload with no data key" do
      expect(described_class.deserialize({}).about).to be_nil
    end

    it "tolerates an empty data array" do
      expect(described_class.deserialize({ "data" => [] }).about).to be_nil
    end

    it "tolerates a partial payload, leaving unrequested fields nil" do
      result = described_class.deserialize({ "data" => [{ "about" => "Open daily" }] })

      expect(result.about).to eq("Open daily")
      expect(result.vertical).to be_nil
      expect(result.email).to be_nil
    end

    it "keeps an unrecognized vertical as the raw string it arrived as" do
      expect(described_class.deserialize({ "data" => [{ "vertical" => "SPACESHIPS" }] }).vertical)
        .to eq("SPACESHIPS")
    end

    it "does not upcase a vertical on the way in" do
      expect(described_class.deserialize({ "data" => [{ "vertical" => "retail" }] }).vertical).to eq("retail")
    end
  end

  describe "#initialize" do
    it "defaults every attribute to nil" do
      expect(described_class.new).to have_attributes(
        messaging_product: nil, about: nil, address: nil, description: nil, email: nil,
        profile_picture_url: nil, websites: nil, vertical: nil
      )
    end

    it "accepts every attribute as a keyword" do
      expect(described_class.new(about: "Open daily", vertical: "RETAIL"))
        .to have_attributes(about: "Open daily", vertical: "RETAIL")
    end
  end
end

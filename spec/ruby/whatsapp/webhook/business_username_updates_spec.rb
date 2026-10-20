# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::BusinessUsernameUpdates do
  describe ".deserialize" do
    it "maps display_phone_number, username, and status" do
      value = described_class.deserialize(
        "display_phone_number" => "15550783881",
        "username" => "jaspersmarket",
        "status" => "approved"
      )

      expect(value.display_phone_number).to eq("15550783881")
      expect(value.username).to eq("jaspersmarket")
      expect(value.status).to eq("approved")
    end

    it "tolerates a missing username, e.g. when status is deleted" do
      value = described_class.deserialize("display_phone_number" => "15550783881", "status" => "deleted")

      expect(value.username).to be_nil
      expect(value.status).to eq("deleted")
    end

    it "keeps the raw value hash when none of the keys are the ones it reads" do
      value = described_class.deserialize("phone_number" => "15550783881", "state" => "approved")

      expect(value.display_phone_number).to be_nil
      expect(value.status).to be_nil
      expect(value.raw).to eq("phone_number" => "15550783881", "state" => "approved")
    end
  end

  describe "#initialize" do
    it "builds a deletion, which carries no username" do
      value = described_class.new(display_phone_number: "15550783881", status: "deleted")

      expect(value.display_phone_number).to eq("15550783881")
      expect(value.status).to eq("deleted")
      expect(value.username).to be_nil
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::UserIdUpdate::IdChange do
  describe ".deserialize" do
    it "maps previous and current" do
      id_change = described_class.deserialize("previous" => "US.OLD", "current" => "US.NEW")

      expect(id_change.previous).to eq("US.OLD")
      expect(id_change.current).to eq("US.NEW")
    end

    it "tolerates a nil hash" do
      id_change = described_class.deserialize(nil)

      expect(id_change.previous).to be_nil
      expect(id_change.current).to be_nil
    end
  end
end

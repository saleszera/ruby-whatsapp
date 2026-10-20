# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::UserIdUpdate::IdChange do
  describe ".deserialize" do
    it "maps previous and current" do
      id_change = described_class.deserialize("previous" => "US.OLD", "current" => "US.NEW")

      expect(id_change.previous).to eq("US.OLD")
      expect(id_change.current).to eq("US.NEW")
    end

    it "returns nil when the key is absent, rather than an all-nil instance" do
      expect(described_class.deserialize(nil)).to be_nil
    end
  end
end

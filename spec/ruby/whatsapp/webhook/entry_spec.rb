# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Entry do
  describe ".deserialize" do
    it "maps id and changes" do
      entry = described_class.deserialize(
        "id" => "102290129340398",
        "changes" => [{ "field" => "messages", "value" => {} }]
      )

      expect(entry.id).to eq("102290129340398")
      expect(entry.changes.length).to eq(1)
      expect(entry.changes.first).to be_a(Whatsapp::Webhook::Change)
    end

    it "tolerates missing changes" do
      entry = described_class.deserialize("id" => "102290129340398")

      expect(entry.changes).to eq([])
    end
  end
end

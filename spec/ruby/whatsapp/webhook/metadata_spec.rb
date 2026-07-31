# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Metadata do
  describe ".deserialize" do
    it "maps display_phone_number and phone_number_id" do
      metadata = described_class.deserialize(
        "display_phone_number" => "15550783881",
        "phone_number_id" => "106540352242922"
      )

      expect(metadata.display_phone_number).to eq("15550783881")
      expect(metadata.phone_number_id).to eq("106540352242922")
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::UnknownField do
  describe ".deserialize" do
    it "wraps the raw hash" do
      field = described_class.deserialize("some_key" => "some_value")

      expect(field["some_key"]).to eq("some_value")
      expect(field.to_h).to eq({ "some_key" => "some_value" })
    end

    it "tolerates a nil value" do
      field = described_class.deserialize(nil)

      expect(field.to_h).to eq({})
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Change do
  describe ".deserialize" do
    it "preserves the field name" do
      change = described_class.deserialize("field" => "messages", "value" => {})

      expect(change.field).to eq("messages")
    end

    it "falls back to UnknownField for a field Meta might add in the future" do
      change = described_class.deserialize("field" => "some_future_field", "value" => { "foo" => "bar" })

      expect(change.value).to be_a(Whatsapp::Webhook::UnknownField)
      expect(change.value["foo"]).to eq("bar")
    end

    it "dispatches the messages field to Whatsapp::Webhook::Messages" do
      change = described_class.deserialize("field" => "messages", "value" => { "messaging_product" => "whatsapp" })

      expect(change.value).to be_a(Whatsapp::Webhook::Messages)
    end

    it "dispatches every one of the 19 documented fields to its own class" do
      Whatsapp::Webhook::Change::FIELDS.each do |field, klass|
        change = described_class.deserialize("field" => field.to_s, "value" => {})

        expect(change.value).to be_a(klass)
      end

      expect(Whatsapp::Webhook::Change::FIELDS.size).to eq(19)
    end
  end
end

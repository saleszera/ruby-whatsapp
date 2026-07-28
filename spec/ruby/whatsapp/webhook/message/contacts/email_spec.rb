# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Contacts::Email do
  describe ".deserialize" do
    it "maps email and type" do
      email = described_class.deserialize("email" => "jane@example.com", "type" => "WORK")

      expect(email.email).to eq("jane@example.com")
      expect(email.type).to eq("WORK")
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Contacts::Org do
  describe ".deserialize" do
    it "maps company, department, and title" do
      org = described_class.deserialize("company" => "Acme Inc.", "department" => "Sales", "title" => "Manager")

      expect(org.company).to eq("Acme Inc.")
      expect(org.department).to eq("Sales")
      expect(org.title).to eq("Manager")
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Contacts::Name do
  describe ".deserialize" do
    it "maps every name field" do
      name = described_class.deserialize(
        "formatted_name" => "Jane Doe", "first_name" => "Jane", "last_name" => "Doe",
        "middle_name" => "M", "prefix" => "Dr", "suffix" => "Jr"
      )

      expect(name.formatted_name).to eq("Jane Doe")
      expect(name.first_name).to eq("Jane")
      expect(name.last_name).to eq("Doe")
      expect(name.middle_name).to eq("M")
      expect(name.prefix).to eq("Dr")
      expect(name.suffix).to eq("Jr")
    end
  end
end

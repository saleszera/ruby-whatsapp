# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::PartnerSolutions do
  describe ".deserialize" do
    it "maps solution_id and event" do
      value = described_class.deserialize("solution_id" => "sol.1", "event" => "DISCONNECTED")

      expect(value.solution_id).to eq("sol.1")
      expect(value.event).to eq("DISCONNECTED")
    end
  end
end

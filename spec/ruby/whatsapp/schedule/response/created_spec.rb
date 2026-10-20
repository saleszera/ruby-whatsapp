# frozen_string_literal: true

RSpec.describe Whatsapp::Schedule::Response::Created do
  describe ".deserialize" do
    it "reads the new schedule's id" do
      expect(described_class.deserialize({ "id" => "1234567890" }).id).to eq("1234567890")
    end

    it "tolerates a nil payload" do
      expect(described_class.deserialize(nil).id).to be_nil
    end
  end
end

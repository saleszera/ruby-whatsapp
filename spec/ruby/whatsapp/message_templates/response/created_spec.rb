# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Response::Created do
  describe ".deserialize" do
    it "maps the create response" do
      result = described_class.deserialize(
        "id" => "1259544702043867", "status" => "PENDING", "category" => "UTILITY"
      )

      expect(result.id).to eq("1259544702043867")
      expect(result.status).to eq("PENDING")
      expect(result.category).to eq("UTILITY")
    end

    it "tolerates a nil payload" do
      result = described_class.deserialize(nil)

      expect(result.id).to be_nil
      expect(result.status).to be_nil
    end
  end

  describe "#approved? and #pending?" do
    it "reports an approved template, as library clones usually are" do
      result = described_class.deserialize("id" => "1", "status" => "APPROVED")

      expect(result).to be_approved
      expect(result).not_to be_pending
    end

    it "reports a template still in review" do
      result = described_class.deserialize("id" => "1", "status" => "PENDING")

      expect(result).to be_pending
      expect(result).not_to be_approved
    end
  end
end

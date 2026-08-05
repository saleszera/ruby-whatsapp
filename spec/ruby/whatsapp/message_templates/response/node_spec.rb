# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Response::Node do
  let(:payload) do
    {
      "id" => "564750795574598",
      "name" => "order_confirmation",
      "status" => "APPROVED",
      "category" => "UTILITY",
      "language" => "en_US",
      "parameter_format" => "POSITIONAL",
      "sub_category" => "ORDER_DETAILS",
      "rejected_reason" => "NONE",
      "previous_category" => "MARKETING",
      "correct_category" => "UTILITY",
      "message_send_ttl_seconds" => 3600,
      "cta_url_link_tracking_opted_out" => false,
      "library_template_name" => "delivery_update_1",
      "quality_score" => { "score" => "GREEN", "date" => 1_700_000_000, "reasons" => [] },
      "components" => [
        { "type" => "BODY", "text" => "Thank you, {{1}}!", "example" => { "body_text" => [["Pablo"]] } },
      ],
    }
  end

  describe ".deserialize" do
    it "maps every documented node field" do
      node = described_class.deserialize(payload)

      expect(node.id).to eq("564750795574598")
      expect(node.name).to eq("order_confirmation")
      expect(node.status).to eq("APPROVED")
      expect(node.category).to eq("UTILITY")
      expect(node.language).to eq("en_US")
      expect(node.parameter_format).to eq("POSITIONAL")
      expect(node.sub_category).to eq("ORDER_DETAILS")
      expect(node.rejected_reason).to eq("NONE")
      expect(node.previous_category).to eq("MARKETING")
      expect(node.correct_category).to eq("UTILITY")
      expect(node.message_send_ttl_seconds).to eq(3600)
      expect(node.cta_url_link_tracking_opted_out).to be(false)
      expect(node.library_template_name).to eq("delivery_update_1")
    end

    it "types the quality score" do
      node = described_class.deserialize(payload)

      expect(node.quality_score).to be_a(Whatsapp::MessageTemplates::Response::QualityScore)
      expect(node.quality_score.score).to eq("GREEN")
    end

    it "leaves components as raw hashes rather than round-tripping the write-side classes" do
      node = described_class.deserialize(payload)

      expect(node.components).to eq(payload["components"])
    end

    it "tolerates a nil payload" do
      expect(described_class.deserialize(nil).id).to be_nil
    end

    it "defaults components to an empty array" do
      expect(described_class.deserialize("id" => "1").components).to eq([])
    end

    it "leaves quality_score nil when absent" do
      expect(described_class.deserialize("id" => "1").quality_score).to be_nil
    end
  end

  describe "status predicates" do
    it "reports whether the template can be sent" do
      expect(described_class.deserialize("status" => "APPROVED")).to be_approved
      expect(described_class.deserialize("status" => "PAUSED")).not_to be_approved
    end

    it "reports a rejected template" do
      expect(described_class.deserialize("status" => "REJECTED")).to be_rejected
    end

    it "reports whether the template may be edited" do
      expect(described_class.deserialize("status" => "APPROVED")).to be_editable
      expect(described_class.deserialize("status" => "REJECTED")).to be_editable
      expect(described_class.deserialize("status" => "PAUSED")).to be_editable
      expect(described_class.deserialize("status" => "PENDING")).not_to be_editable
      expect(described_class.deserialize("status" => "DISABLED")).not_to be_editable
    end
  end
end

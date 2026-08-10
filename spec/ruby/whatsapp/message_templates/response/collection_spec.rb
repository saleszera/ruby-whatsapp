# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Response::Collection do
  let(:payload) do
    {
      "data" => [
        { "id" => "1", "name" => "order_confirmation", "status" => "APPROVED" },
        { "id" => "2", "name" => "shipping_update", "status" => "PENDING" },
      ],
      "paging" => { "cursors" => { "before" => "BEFORE_CURSOR", "after" => "AFTER_CURSOR" } },
      "summary" => {
        "total_count" => 12,
        "message_template_count" => 12,
        "message_template_limit" => 250,
        "are_translations_complete" => true,
      },
    }
  end

  describe ".deserialize" do
    it "types each element of data as a node" do
      collection = described_class.deserialize(payload)

      expect(collection.data.map(&:name)).to eq(%w[order_confirmation shipping_update])
      expect(collection.data).to all(be_a(Whatsapp::MessageTemplates::Response::Node))
    end

    it "types the paging cursors" do
      collection = described_class.deserialize(payload)

      expect(collection.paging.before).to eq("BEFORE_CURSOR")
      expect(collection.paging.after).to eq("AFTER_CURSOR")
    end

    it "types the summary" do
      collection = described_class.deserialize(payload)

      expect(collection.summary.total_count).to eq(12)
      expect(collection.summary.message_template_count).to eq(12)
      expect(collection.summary.message_template_limit).to eq(250)
      expect(collection.summary.are_translations_complete).to be(true)
    end

    it "tolerates a response with no paging or summary" do
      collection = described_class.deserialize("data" => [])

      expect(collection.data).to eq([])
      expect(collection.paging).to be_nil
      expect(collection.summary).to be_nil
    end

    it "tolerates a nil payload" do
      expect(described_class.deserialize(nil).data).to eq([])
    end
  end

  describe "enumerability" do
    it "iterates the templates directly" do
      collection = described_class.deserialize(payload)

      expect(collection.map(&:id)).to eq(%w[1 2])
      expect(collection.count).to eq(2)
      expect(collection.select(&:approved?).map(&:name)).to eq(%w[order_confirmation])
    end
  end

  describe "#next_cursor" do
    it "returns the after cursor for paging forward" do
      expect(described_class.deserialize(payload).next_cursor).to eq("AFTER_CURSOR")
    end

    it "is nil when there is no paging information" do
      expect(described_class.deserialize("data" => []).next_cursor).to be_nil
    end
  end

  describe "#remaining" do
    it "reports the headroom against the per-WABA template limit" do
      expect(described_class.deserialize(payload).remaining).to eq(238)
    end

    it "is nil when the summary is absent" do
      expect(described_class.deserialize("data" => []).remaining).to be_nil
    end
  end
end

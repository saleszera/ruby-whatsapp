# frozen_string_literal: true

RSpec.describe Whatsapp::Schedule::Response::Collection do
  let(:payload) do
    {
      "data" => [
        { "id" => "1", "name" => "Black Friday", "delivery_time" => 1_764_000_000, "status" => "SCHEDULED" },
        { "id" => "2", "name" => "Cyber Monday", "delivery_time" => 1_764_300_000, "status" => "COMPLETED" },
      ],
      "paging" => {
        "cursors" => { "before" => "BEFORE_CURSOR", "after" => "AFTER_CURSOR" },
        "next" => "https://graph.facebook.com/v24.0/WABA_ID/schedules?after=AFTER_CURSOR",
      },
    }
  end

  describe ".deserialize" do
    it "types each element of data as a node" do
      collection = described_class.deserialize(payload)

      expect(collection.data.map(&:name)).to eq(["Black Friday", "Cyber Monday"])
      expect(collection.data).to all(be_a(Whatsapp::Schedule::Response::Node))
    end

    it "types the paging cursors with the shared Graph API paging class" do
      collection = described_class.deserialize(payload)

      expect(collection.paging).to be_a(Whatsapp::MessageTemplates::Response::Paging)
      expect(collection.paging.before).to eq("BEFORE_CURSOR")
      expect(collection.paging.after).to eq("AFTER_CURSOR")
    end

    it "tolerates a response with no paging" do
      collection = described_class.deserialize({ "data" => [] })

      expect(collection.data).to eq([])
      expect(collection.paging).to be_nil
    end

    it "tolerates a nil payload" do
      expect(described_class.deserialize(nil).data).to eq([])
    end
  end

  describe "#next_cursor" do
    it "is the after cursor, ready to pass back as after:" do
      expect(described_class.deserialize(payload).next_cursor).to eq("AFTER_CURSOR")
    end

    it "is nil when there is no paging" do
      expect(described_class.deserialize({ "data" => [] }).next_cursor).to be_nil
    end
  end

  describe "enumerability" do
    it "iterates the schedules directly" do
      collection = described_class.deserialize(payload)

      expect(collection.select(&:scheduled?).map(&:id)).to eq(["1"])
      expect(collection.count).to eq(2)
    end
  end
end

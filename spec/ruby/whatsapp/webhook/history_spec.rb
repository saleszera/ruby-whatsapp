# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::History do
  describe ".deserialize" do
    it "maps phase, chunk_order, progress, and threads" do
      value = described_class.deserialize(
        "metadata" => { "phase" => 1, "chunk_order" => 1, "progress" => 50 },
        "threads" => [{ "id" => "thread.1" }]
      )

      expect(value.phase).to eq(1)
      expect(value.chunk_order).to eq(1)
      expect(value.progress).to eq(50)
      expect(value.threads).to eq([{ "id" => "thread.1" }])
    end

    it "tolerates missing metadata and threads" do
      value = described_class.deserialize({})

      expect(value.phase).to be_nil
      expect(value.threads).to eq([])
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::ContactBook::Deletion do
  describe ".deserialize" do
    it "maps messaging_product, success, and deleted" do
      deletion = described_class.deserialize(
        "messaging_product" => "whatsapp", "success" => true, "deleted" => true
      )

      expect(deletion.messaging_product).to eq("whatsapp")
      expect(deletion.success).to be(true)
      expect(deletion.deleted).to be(true)
    end

    # The case the class exists for: the request worked, there was simply nothing stored.
    it "reports a successful request that found no entry" do
      deletion = described_class.deserialize("success" => true, "deleted" => false)

      expect(deletion.success).to be(true)
      expect(deletion.deleted).to be(false)
    end

    it "defaults both booleans to false for an empty and a nil body" do
      expect(described_class.deserialize({}).success).to be(false)
      expect(described_class.deserialize({}).deleted).to be(false)
      expect(described_class.deserialize(nil).success).to be(false)
      expect(described_class.deserialize(nil).deleted).to be(false)
    end

    it "treats anything but a real true as false" do
      deletion = described_class.deserialize("success" => "true", "deleted" => 1)

      expect(deletion.success).to be(false)
      expect(deletion.deleted).to be(false)
    end
  end
end

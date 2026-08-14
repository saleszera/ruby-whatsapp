# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Response do
  describe ".deserialize" do
    it "reads the success flag" do
      expect(described_class.deserialize("success" => true).success).to be(true)
    end

    it "treats anything other than true as unsuccessful" do
      expect(described_class.deserialize("success" => false).success).to be(false)
      expect(described_class.deserialize("success" => "true").success).to be(false)
      expect(described_class.deserialize({}).success).to be(false)
    end

    it "tolerates a nil payload" do
      expect(described_class.deserialize(nil).success).to be(false)
    end
  end
end

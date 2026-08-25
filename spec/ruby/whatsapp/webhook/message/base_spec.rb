# frozen_string_literal: true

RSpec.describe Whatsapp::Webhook::Message::Base do
  describe ".common_attributes" do
    it "maps the shared envelope, including from_user_id and from_parent_user_id" do
      attributes = described_class.common_attributes(
        "from" => "16315551181",
        "from_user_id" => "US.13491208655302741918",
        "from_parent_user_id" => "US.ENT.11815799212886844830",
        "id" => "ABGGFlA5Fpa",
        "timestamp" => "1504902988",
        "type" => "text"
      )

      expect(attributes[:from]).to eq("16315551181")
      expect(attributes[:from_user_id]).to eq("US.13491208655302741918")
      expect(attributes[:from_parent_user_id]).to eq("US.ENT.11815799212886844830")
      expect(attributes[:id]).to eq("ABGGFlA5Fpa")
      expect(attributes[:timestamp]).to eq("1504902988")
      expect(attributes[:type]).to eq("text")
      expect(attributes[:context]).to be_nil
      expect(attributes[:referral]).to be_nil
    end

    it "tolerates a missing from_user_id and from_parent_user_id, e.g. when the user has not adopted BSUID" do
      attributes = described_class.common_attributes("from" => "16315551181", "type" => "text")

      expect(attributes[:from_user_id]).to be_nil
      expect(attributes[:from_parent_user_id]).to be_nil
    end
  end
end

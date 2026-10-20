# frozen_string_literal: true

RSpec.describe Whatsapp::Schedule::Response::Node do
  let(:payload) do
    {
      "id" => "1234567890",
      "name" => "Black Friday",
      "description" => "Black Friday promo to VIP customers",
      "delivery_time" => 1_764_000_000,
      "status" => "SCHEDULED",
    }
  end

  describe ".deserialize" do
    it "reads every documented field" do
      node = described_class.deserialize(payload)

      expect(node).to have_attributes(
        id: "1234567890",
        name: "Black Friday",
        description: "Black Friday promo to VIP customers",
        delivery_time: 1_764_000_000,
        status: "SCHEDULED"
      )
    end

    it "tolerates a nil payload" do
      node = described_class.deserialize(nil)

      expect(node.id).to be_nil
      expect(node.status).to be_nil
    end

    it "tolerates the default field set, which omits id" do
      node = described_class.deserialize(payload.except("id"))

      expect(node.id).to be_nil
      expect(node.name).to eq("Black Friday")
    end

    it "passes an undocumented status value through untouched" do
      node = described_class.deserialize({ "status" => "SOMETHING_NEW" })

      expect(node.status).to eq("SOMETHING_NEW")
    end
  end

  describe "status predicates" do
    {
      scheduled?: "SCHEDULED",
      sending?: "SENDING",
      completed?: "COMPLETED",
      failed?: "FAILED",
    }.each do |predicate, status|
      it "#{predicate} is true only for #{status}" do
        Whatsapp::Schedule::Statuses::ALL.each do |candidate|
          node = described_class.deserialize({ "status" => candidate })

          expect(node.public_send(predicate)).to be(candidate == status)
        end
      end
    end

    it "answers false to every predicate when the status is absent" do
      node = described_class.deserialize({})

      expect(node).not_to be_scheduled
      expect(node).not_to be_sending
      expect(node).not_to be_completed
      expect(node).not_to be_failed
    end
  end
end

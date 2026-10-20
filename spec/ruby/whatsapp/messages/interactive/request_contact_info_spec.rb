# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Interactive::RequestContactInfo do
  describe "#serialize" do
    it "carries the action name and nothing else" do
      expect(described_class.new.serialize).to eq(name: "request_contact_info")
    end

    # Every other action kind serializes a `parameters` key; this one has nothing to put
    # in it, which is the whole difference.
    it "has no parameters key" do
      expect(described_class.new.serialize).not_to have_key(:parameters)
    end
  end

  describe ".serialize" do
    it "works with no arguments at all" do
      expect(described_class.serialize).to eq(name: "request_contact_info")
    end

    # Interactive calls this as `serialize(**action)`, so it must accept an empty splat.
    it "works with an empty keyword splat, as Interactive calls it" do
      expect(described_class.serialize(**{})).to eq(name: "request_contact_info")
    end

    it "accepts the name spelled out, mirroring Meta's example payload" do
      expect(described_class.serialize(name: "request_contact_info")).to eq(name: "request_contact_info")
    end
  end

  describe "validation" do
    it "rejects any other action name" do
      expect { described_class.new(name: "share_contact") }
        .to raise_error(ActiveModel::ValidationError, /Name is not included in the list/)
    end
  end
end

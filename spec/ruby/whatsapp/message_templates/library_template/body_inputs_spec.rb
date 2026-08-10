# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::LibraryTemplate::BodyInputs do
  describe "#serialize" do
    it "emits only the toggles that were set" do
      expect(described_class.new(add_contact_number: true, code_expiration_minutes: 5).serialize)
        .to eq(add_contact_number: true, code_expiration_minutes: 5)
    end

    it "emits every documented toggle" do
      result = described_class.new(
        add_contact_number: true, add_learn_more_link: true, add_security_recommendation: true,
        add_track_package_link: true, code_expiration_minutes: 10
      ).serialize

      expect(result).to eq(
        add_contact_number: true, add_learn_more_link: true, add_security_recommendation: true,
        add_track_package_link: true, code_expiration_minutes: 10
      )
    end

    it "keeps explicitly false toggles" do
      expect(described_class.new(add_contact_number: false).serialize).to eq(add_contact_number: false)
    end

    it "is empty when nothing is set" do
      expect(described_class.new.serialize).to eq({})
    end
  end

  describe "validations" do
    it "accepts a code expiry within 1..90" do
      expect { described_class.new(code_expiration_minutes: 90) }.not_to raise_error
    end

    it "rejects a code expiry outside 1..90" do
      expect { described_class.new(code_expiration_minutes: 91) }
        .to raise_error(ActiveModel::ValidationError, /must be in 1..90/)
    end
  end
end

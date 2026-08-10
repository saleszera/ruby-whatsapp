# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Component::LimitedTimeOffer do
  describe "#serialize" do
    it "nests the offer under a limited_time_offer key" do
      expect(described_class.new(text: "Expiring offer!", has_expiration: true).serialize)
        .to eq(type: "LIMITED_TIME_OFFER", limited_time_offer: { text: "Expiring offer!", has_expiration: true })
    end

    it "omits has_expiration when it is not set" do
      expect(described_class.new(text: "Expiring offer!").serialize)
        .to eq(type: "LIMITED_TIME_OFFER", limited_time_offer: { text: "Expiring offer!" })
    end

    it "keeps an explicit false has_expiration" do
      expect(described_class.new(text: "Offer", has_expiration: false).serialize[:limited_time_offer])
        .to eq(text: "Offer", has_expiration: false)
    end
  end

  describe "validations" do
    it "requires text" do
      expect { described_class.new(text: nil) }
        .to raise_error(ActiveModel::ValidationError, /Text can't be blank/)
    end

    it "accepts text at the 16 character limit" do
      expect { described_class.new(text: "a" * 16) }.not_to raise_error
    end

    it "rejects text over 16 characters" do
      expect { described_class.new(text: "a" * 17) }
        .to raise_error(ActiveModel::ValidationError, /Text is too long/)
    end
  end
end

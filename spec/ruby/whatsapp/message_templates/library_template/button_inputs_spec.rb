# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::LibraryTemplate::ButtonInputs do
  describe "#serialize" do
    it "emits a URL button input" do
      result = described_class.new(
        type: "URL", url: { base_url: "https://www.example.com/{{1}}", url_suffix_example: "https://www.example.com/demo" }
      ).serialize

      expect(result).to eq(
        type: "URL",
        url: { base_url: "https://www.example.com/{{1}}", url_suffix_example: "https://www.example.com/demo" }
      )
    end

    it "emits a phone number button input" do
      expect(described_class.new(type: "PHONE_NUMBER", phone_number: "+16315551010").serialize)
        .to eq(type: "PHONE_NUMBER", phone_number: "+16315551010")
    end

    it "emits an OTP button input" do
      expect(described_class.new(type: "OTP", otp_type: "COPY_CODE", zero_tap_terms_accepted: true).serialize)
        .to eq(type: "OTP", otp_type: "COPY_CODE", zero_tap_terms_accepted: true)
    end

    it "emits an APP button input with its supported apps" do
      result = described_class.new(
        type: "APP", supported_apps: [{ package_name: "com.example.app", signature_hash: "abc" }]
      ).serialize

      expect(result).to eq(
        type: "APP", supported_apps: [{ package_name: "com.example.app", signature_hash: "abc" }]
      )
    end

    it "emits a bare type for the non-customisable inputs" do
      expect(described_class.new(type: "QUICK_REPLY").serialize).to eq(type: "QUICK_REPLY")
    end

    it "accepts lowercase and normalizes to Meta's uppercase" do
      expect(described_class.new(type: :quick_reply).serialize[:type]).to eq("QUICK_REPLY")
    end
  end

  describe "validations" do
    it "requires a type" do
      expect { described_class.new(type: nil) }
        .to raise_error(ActiveModel::ValidationError, /Type can't be blank/)
    end

    it "rejects an unknown type" do
      expect { described_class.new(type: "TELEPATHY") }
        .to raise_error(ActiveModel::ValidationError, /Type is not included/)
    end

    it "requires a base_url for a URL input" do
      expect { described_class.new(type: "URL", url: { url_suffix_example: "https://x.test/demo" }) }
        .to raise_error(ActiveModel::ValidationError, /base_url/)
    end

    it "requires a url object for a URL input" do
      expect { described_class.new(type: "URL") }
        .to raise_error(ActiveModel::ValidationError, /base_url/)
    end

    it "requires a phone_number for a PHONE_NUMBER input" do
      expect { described_class.new(type: "PHONE_NUMBER") }
        .to raise_error(ActiveModel::ValidationError, /Phone number can't be blank/)
    end

    it "requires supported_apps for an APP input" do
      expect { described_class.new(type: "APP") }
        .to raise_error(ActiveModel::ValidationError, /Supported apps can't be blank/)
    end

    it "validates each supported app" do
      expect { described_class.new(type: "APP", supported_apps: [{ package_name: "com.a", signature_hash: nil }]) }
        .to raise_error(ActiveModel::ValidationError, /Signature hash can't be blank/)
    end
  end
end

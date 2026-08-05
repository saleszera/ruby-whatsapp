# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Button::Otp do
  describe "#serialize" do
    it "emits a copy-code OTP button" do
      expect(described_class.new(otp_type: "COPY_CODE").serialize)
        .to eq(type: "OTP", otp_type: "COPY_CODE")
    end

    it "emits a one-tap OTP button with its supported apps" do
      result = described_class.new(
        otp_type: "ONE_TAP",
        supported_apps: [{ package_name: "com.example.luckyshrub", signature_hash: "K8a/AINcGX7" }]
      ).serialize

      expect(result).to eq(
        type: "OTP", otp_type: "ONE_TAP",
        supported_apps: [{ package_name: "com.example.luckyshrub", signature_hash: "K8a/AINcGX7" }]
      )
    end

    it "emits a zero-tap OTP button with the terms flag" do
      result = described_class.new(
        otp_type: "ZERO_TAP", zero_tap_terms_accepted: true,
        supported_apps: [{ package_name: "com.example.app", signature_hash: "abc" }]
      ).serialize

      expect(result[:zero_tap_terms_accepted]).to be(true)
    end

    it "accepts a lowercase otp_type and normalizes it" do
      expect(described_class.new(otp_type: :copy_code).serialize[:otp_type]).to eq("COPY_CODE")
    end
  end

  describe "validations" do
    it "requires an otp_type" do
      expect { described_class.new(otp_type: nil) }
        .to raise_error(ActiveModel::ValidationError, /Otp type can't be blank/)
    end

    it "rejects an unknown otp_type" do
      expect { described_class.new(otp_type: "TWO_TAP") }
        .to raise_error(ActiveModel::ValidationError, /Otp type is not included/)
    end

    it "requires supported_apps for ONE_TAP" do
      expect { described_class.new(otp_type: "ONE_TAP") }
        .to raise_error(ActiveModel::ValidationError, /Supported apps can't be blank/)
    end

    it "requires supported_apps for ZERO_TAP" do
      expect { described_class.new(otp_type: "ZERO_TAP", zero_tap_terms_accepted: true) }
        .to raise_error(ActiveModel::ValidationError, /Supported apps can't be blank/)
    end

    it "does not require supported_apps for COPY_CODE" do
      expect { described_class.new(otp_type: "COPY_CODE") }.not_to raise_error
    end

    it "requires zero_tap_terms_accepted to be true for ZERO_TAP" do
      expect do
        described_class.new(
          otp_type: "ZERO_TAP",
          supported_apps: [{ package_name: "com.example.app", signature_hash: "abc" }]
        )
      end.to raise_error(ActiveModel::ValidationError, /must be accepted/)
    end

    it "rejects a label, which Meta localises itself" do
      expect { described_class.new(otp_type: "COPY_CODE", text: "Copy") }
        .to raise_error(ActiveModel::ValidationError, /cannot be set/)
    end

    it "rejects autofill_text, which Meta localises itself" do
      expect { described_class.new(otp_type: "ONE_TAP", autofill_text: "Autofill") }
        .to raise_error(ActiveModel::ValidationError, /cannot be set/)
    end

    it "validates each supported app" do
      expect do
        described_class.new(
          otp_type: "ONE_TAP", supported_apps: [{ package_name: "com.example.app", signature_hash: nil }]
        )
      end.to raise_error(ActiveModel::ValidationError, /Signature hash can't be blank/)
    end

    it "surfaces a missing supported-app key as an ArgumentError" do
      expect { described_class.new(otp_type: "ONE_TAP", supported_apps: [{ package_name: "com.example.app" }]) }
        .to raise_error(ArgumentError, /missing keyword: :signature_hash/)
    end

    it "accepts already-built supported app objects" do
      app = described_class::SupportedApp.new(package_name: "com.example.app", signature_hash: "abc")

      expect(described_class.new(otp_type: "ONE_TAP", supported_apps: [app]).serialize[:supported_apps])
        .to eq([{ package_name: "com.example.app", signature_hash: "abc" }])
    end
  end
end

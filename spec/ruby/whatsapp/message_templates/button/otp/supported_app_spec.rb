# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Button::Otp::SupportedApp do
  describe "#serialize" do
    it "emits the package name and signature hash" do
      expect(described_class.new(package_name: "com.example.luckyshrub", signature_hash: "K8a/AINcGX7").serialize)
        .to eq(package_name: "com.example.luckyshrub", signature_hash: "K8a/AINcGX7")
    end
  end

  describe "validations" do
    it "requires a package name" do
      expect { described_class.new(package_name: nil, signature_hash: "abc") }
        .to raise_error(ActiveModel::ValidationError, /Package name can't be blank/)
    end

    it "requires a signature hash" do
      expect { described_class.new(package_name: "com.example.app", signature_hash: nil) }
        .to raise_error(ActiveModel::ValidationError, /Signature hash can't be blank/)
    end
  end

  describe ".serialize" do
    it "exposes a class-level shorthand" do
      expect(described_class.serialize(package_name: "com.a", signature_hash: "h"))
        .to eq(package_name: "com.a", signature_hash: "h")
    end
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Button::Url do
  describe "#serialize" do
    it "emits a static URL button without an example" do
      expect(described_class.new(text: "Contact Support", url: "https://www.luckyshrub.com/support").serialize)
        .to eq(type: "URL", text: "Contact Support", url: "https://www.luckyshrub.com/support")
    end

    it "emits the example as a flat array on the button when the URL has a variable" do
      result = described_class.new(
        text: "Shop Now", url: "https://www.luckyshrub.com/shop?promo={{1}}", example: "summer2023"
      ).serialize

      expect(result).to eq(
        type: "URL", text: "Shop Now", url: "https://www.luckyshrub.com/shop?promo={{1}}",
        example: ["summer2023"]
      )
    end

    it "passes an example already given as an array through unchanged" do
      result = described_class.new(
        text: "Shop", url: "https://x.test/{{1}}", example: ["summer2023"]
      ).serialize

      expect(result[:example]).to eq(["summer2023"])
    end

    it "supports a named variable" do
      result = described_class.new(
        text: "Shop", url: "https://x.test/shop?promo={{promo_code}}", example: "summer"
      ).serialize

      expect(result[:url]).to eq("https://x.test/shop?promo={{promo_code}}")
    end
  end

  describe "validations" do
    it "requires text" do
      expect { described_class.new(text: nil, url: "https://x.test") }
        .to raise_error(ActiveModel::ValidationError, /Text can't be blank/)
    end

    it "rejects text over 25 characters" do
      expect { described_class.new(text: "a" * 26, url: "https://x.test") }
        .to raise_error(ActiveModel::ValidationError, /Text is too long/)
    end

    it "requires a url" do
      expect { described_class.new(text: "Shop", url: nil) }
        .to raise_error(ActiveModel::ValidationError, /Url can't be blank/)
    end

    it "rejects a url over 2000 characters" do
      expect { described_class.new(text: "Shop", url: "https://x.test/#{'a' * 2000}") }
        .to raise_error(ActiveModel::ValidationError, /Url is too long/)
    end

    it "rejects more than one variable" do
      expect { described_class.new(text: "Shop", url: "https://x.test/{{1}}/{{2}}", example: %w[a b]) }
        .to raise_error(ActiveModel::ValidationError, /at most one variable/)
    end

    it "rejects a variable that is not at the end of the url" do
      expect { described_class.new(text: "Shop", url: "https://x.test/{{1}}/details", example: "a") }
        .to raise_error(ActiveModel::ValidationError, /must be at the end/)
    end

    it "requires an example when the url has a variable" do
      expect { described_class.new(text: "Shop", url: "https://x.test/{{1}}") }
        .to raise_error(ActiveModel::ValidationError, /Example can't be blank/)
    end

    it "does not require an example for a static url" do
      expect { described_class.new(text: "Shop", url: "https://x.test/shop") }.not_to raise_error
    end
  end
end

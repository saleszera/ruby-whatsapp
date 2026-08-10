# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::ComponentSet do
  let(:categories) { Whatsapp::MessageTemplates::Categories }
  let(:body) { { type: :body, text: "Thank you for your order." } }

  describe "#serialize" do
    it "serializes each component in declared order" do
      set = described_class.new(components: [
        { type: :header, format: "TEXT", text: "Order update" },
        body,
        { type: :footer, text: "Thanks for shopping" },
      ])

      expect(set.serialize.map { |c| c[:type] }).to eq(%w[HEADER BODY FOOTER])
    end

    it "accepts already-built components" do
      built = Whatsapp::MessageTemplates::Component::Body.new(text: "Hi")

      expect(described_class.new(components: [built]).serialize).to eq([{ type: "BODY", text: "Hi" }])
    end

    it "threads the parameter format into every component" do
      set = described_class.new(
        components: [{ type: :body, text: "Hi {{name}}", example: { name: "Pablo" } }],
        parameter_format: Whatsapp::MessageTemplates::ParameterFormats::NAMED
      )

      expect(set.serialize.first[:example]).to eq(body_text_named_params: [{ param_name: "name", example: "Pablo" }])
    end
  end

  describe "structural rules" do
    it "requires a body" do
      expect { described_class.new(components: [{ type: :footer, text: "Bye" }]) }
        .to raise_error(ActiveModel::ValidationError, /requires exactly one BODY/)
    end

    it "rejects two bodies" do
      expect { described_class.new(components: [body, body]) }
        .to raise_error(ActiveModel::ValidationError, /requires exactly one BODY/)
    end

    it "rejects two headers" do
      header = { type: :header, format: "LOCATION" }

      expect { described_class.new(components: [header, header, body]) }
        .to raise_error(ActiveModel::ValidationError, /at most one HEADER/)
    end

    it "rejects two footers" do
      footer = { type: :footer, text: "Bye" }

      expect { described_class.new(components: [body, footer, footer]) }
        .to raise_error(ActiveModel::ValidationError, /at most one FOOTER/)
    end

    it "requires at least one component" do
      expect { described_class.new(components: []) }
        .to raise_error(ActiveModel::ValidationError, /Components can't be blank/)
    end
  end

  describe "location header rules" do
    let(:location) { { type: :header, format: "LOCATION" } }

    it "allows a location header on a utility template" do
      expect { described_class.new(components: [location, body], category: categories::UTILITY) }.not_to raise_error
    end

    it "allows a location header on a marketing template" do
      expect { described_class.new(components: [location, body], category: categories::MARKETING) }.not_to raise_error
    end

    it "rejects a location header on an authentication template" do
      expect { described_class.new(components: [location, body], category: categories::AUTHENTICATION) }
        .to raise_error(ActiveModel::ValidationError, /LOCATION header is only supported/)
    end

    it "skips the check when no category is supplied, as when editing components" do
      expect { described_class.new(components: [location, body]) }.not_to raise_error
    end
  end

  describe "carousel rules" do
    let(:carousel) do
      {
        type: :carousel,
        cards: Array.new(2) do
          { header: { format: "IMAGE", header_handle: "4::aW" }, buttons: [{ type: :quick_reply, text: "More" }] }
        end,
      }
    end

    it "allows a carousel on a marketing template" do
      expect { described_class.new(components: [body, carousel], category: categories::MARKETING) }.not_to raise_error
    end

    it "rejects a carousel on a utility template" do
      expect { described_class.new(components: [body, carousel], category: categories::UTILITY) }
        .to raise_error(ActiveModel::ValidationError, /CAROUSEL is only supported on MARKETING/)
    end
  end

  describe "limited-time offer rules" do
    let(:offer) { { type: :limited_time_offer, text: "Expiring offer!" } }
    let(:copy_code) { { type: :copy_code, example: "CARIBE25" } }
    let(:url) { { type: :url, text: "Book now!", url: "https://x.test/o?c={{1}}", example: "n3mtql" } }

    def offer_components(**overrides)
      {
        offer:,
        body: { type: :body, text: "Use code {{1}}", example: ["CARIBE25"] },
        buttons: { type: :buttons, buttons: [copy_code, url] },
      }.merge(overrides).values
    end

    it "accepts a valid limited-time offer template" do
      expect { described_class.new(components: offer_components, category: categories::MARKETING) }.not_to raise_error
    end

    it "rejects it on a non-marketing template" do
      expect { described_class.new(components: offer_components, category: categories::UTILITY) }
        .to raise_error(ActiveModel::ValidationError, /LIMITED_TIME_OFFER is only supported on MARKETING/)
    end

    it "forbids a footer" do
      components = offer_components + [{ type: :footer, text: "Small print" }]

      expect { described_class.new(components:, category: categories::MARKETING) }
        .to raise_error(ActiveModel::ValidationError, /FOOTER is not allowed/)
    end

    it "caps the body at 600 characters" do
      components = offer_components(body: { type: :body, text: "a" * 601 })

      expect { described_class.new(components:, category: categories::MARKETING) }
        .to raise_error(ActiveModel::ValidationError, /600 characters/)
    end

    it "allows a body at 600 characters" do
      components = offer_components(body: { type: :body, text: "a" * 600 })

      expect { described_class.new(components:, category: categories::MARKETING) }.not_to raise_error
    end

    it "caps the copy code example at 15 characters" do
      components = offer_components(
        buttons: { type: :buttons, buttons: [{ type: :copy_code, example: "a" * 16 }, url] }
      )

      expect { described_class.new(components:, category: categories::MARKETING) }
        .to raise_error(ActiveModel::ValidationError, /15 characters/)
    end

    it "requires the copy code button to come first" do
      components = offer_components(buttons: { type: :buttons, buttons: [url, copy_code] })

      expect { described_class.new(components:, category: categories::MARKETING) }
        .to raise_error(ActiveModel::ValidationError, /copy-code button must be first/)
    end

    it "restricts the header to image or video" do
      components = offer_components + [{ type: :header, format: "TEXT", text: "Offer" }]

      expect { described_class.new(components:, category: categories::MARKETING) }
        .to raise_error(ActiveModel::ValidationError, /header must be IMAGE or VIDEO/)
    end

    it "allows an image header" do
      components = offer_components + [{ type: :header, format: "IMAGE", header_handle: "4::aW" }]

      expect { described_class.new(components:, category: categories::MARKETING) }.not_to raise_error
    end
  end

  describe "#find and #api_types" do
    it "looks up a component by wire type" do
      set = described_class.new(components: [body, { type: :footer, text: "Bye" }])

      expect(set.find("BODY")).to be_a(Whatsapp::MessageTemplates::Component::Body)
      expect(set.find("CAROUSEL")).to be_nil
      expect(set.api_types).to eq(%w[BODY FOOTER])
    end
  end
end

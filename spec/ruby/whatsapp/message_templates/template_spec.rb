# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Template do
  let(:categories) { Whatsapp::MessageTemplates::Categories }
  let(:formats) { Whatsapp::MessageTemplates::ParameterFormats }
  let(:body) { { type: :body, text: "Thank you for your order." } }

  def template(**overrides)
    described_class.new(
      name: "order_confirmation", language: "en_US", category: categories::UTILITY, components: [body],
      **overrides
    )
  end

  describe "#serialize" do
    it "emits the documented create payload" do
      result = described_class.new(
        name: "order_confirmation", language: "en_US", category: "utility",
        parameter_format: "named",
        components: [
          {
            type: :body,
            text: "Thank you, {{first_name}}! Your order number is {{order_number}}.",
            example: { first_name: "Pablo", order_number: "860198-230332" },
          },
        ]
      ).serialize

      expect(result).to eq(
        name: "order_confirmation",
        language: "en_US",
        category: "UTILITY",
        parameter_format: "NAMED",
        components: [
          {
            type: "BODY",
            text: "Thank you, {{first_name}}! Your order number is {{order_number}}.",
            example: {
              body_text_named_params: [
                { param_name: "first_name", example: "Pablo" },
                { param_name: "order_number", example: "860198-230332" },
              ],
            },
          },
        ]
      )
    end

    it "defaults the parameter format to positional" do
      expect(template.serialize[:parameter_format]).to eq(formats::POSITIONAL)
    end

    it "emits languages instead of language for the upsert form" do
      result = template(language: nil, languages: %w[en_US es_ES]).serialize

      expect(result[:languages]).to eq(%w[en_US es_ES])
      expect(result).not_to have_key(:language)
    end

    it "includes the optional fields when set" do
      result = template(
        sub_category: "ORDER_DETAILS", message_send_ttl_seconds: 3600,
        allow_category_change: true, cta_url_link_tracking_opted_out: false
      ).serialize

      expect(result).to include(
        sub_category: "ORDER_DETAILS", message_send_ttl_seconds: 3600,
        allow_category_change: true, cta_url_link_tracking_opted_out: false
      )
    end

    it "omits the optional fields when unset" do
      expect(template.serialize.keys)
        .to contain_exactly(:name, :language, :category, :parameter_format, :components)
    end
  end

  describe "name validations" do
    it "requires a name" do
      expect { template(name: nil) }.to raise_error(ActiveModel::ValidationError, /Name can't be blank/)
    end

    it "rejects uppercase characters" do
      expect { template(name: "OrderConfirmation") }
        .to raise_error(ActiveModel::ValidationError, /lowercase alphanumeric/)
    end

    it "rejects spaces and hyphens" do
      expect { template(name: "order confirmation") }
        .to raise_error(ActiveModel::ValidationError, /lowercase alphanumeric/)
      expect { template(name: "order-confirmation") }
        .to raise_error(ActiveModel::ValidationError, /lowercase alphanumeric/)
    end

    it "accepts lowercase alphanumerics and underscores" do
      expect { template(name: "order_confirmation_v2") }.not_to raise_error
    end

    it "rejects a name over 512 characters" do
      expect { template(name: "a" * 513) }.to raise_error(ActiveModel::ValidationError, /Name is too long/)
    end
  end

  describe "language validations" do
    it "requires a language or languages" do
      expect { template(language: nil) }
        .to raise_error(ActiveModel::ValidationError, /requires either language or languages/)
    end

    it "rejects both together" do
      expect { template(languages: %w[es_ES]) }
        .to raise_error(ActiveModel::ValidationError, /cannot be combined/)
    end

    it "rejects an unsupported language code" do
      expect { template(language: "kl_KL") }
        .to raise_error(ActiveModel::ValidationError, /not a valid WhatsApp language code/)
    end

    it "rejects an unsupported code inside languages" do
      expect { template(language: nil, languages: %w[en_US kl_KL]) }
        .to raise_error(ActiveModel::ValidationError, /not a valid WhatsApp language code/)
    end
  end

  describe "category validations" do
    it "requires a category" do
      expect { template(category: nil) }.to raise_error(ActiveModel::ValidationError, /Category can't be blank/)
    end

    it "rejects an unknown category" do
      expect { template(category: "PROMOTIONAL") }
        .to raise_error(ActiveModel::ValidationError, /Category is not included/)
    end

    it "accepts every documented category" do
      expect { template(category: categories::MARKETING) }.not_to raise_error
      expect { template(category: categories::UTILITY) }.not_to raise_error
      expect { template(category: categories::AUTHENTICATION) }.not_to raise_error
    end
  end

  describe "other field validations" do
    it "rejects an unknown parameter format" do
      expect { template(parameter_format: "INTERPOLATED") }
        .to raise_error(ActiveModel::ValidationError, /Parameter format is not included/)
    end

    it "rejects an unknown sub category" do
      expect { template(sub_category: "ORDER_VIBES") }
        .to raise_error(ActiveModel::ValidationError, /Sub category is not included/)
    end

    it "rejects a non-integer ttl" do
      expect { template(message_send_ttl_seconds: "soon") }
        .to raise_error(ActiveModel::ValidationError, /must be an integer/)
    end
  end

  describe "component delegation" do
    it "surfaces cross-component failures from the component set" do
      expect { template(components: [{ type: :footer, text: "Bye" }]) }
        .to raise_error(ActiveModel::ValidationError, /requires exactly one BODY/)
    end

    it "passes the category through so category-dependent rules apply" do
      carousel = {
        type: :carousel,
        cards: Array.new(2) do
          { header: { format: "IMAGE", header_handle: "4::aW" }, buttons: [{ type: :quick_reply, text: "More" }] }
        end,
      }

      expect { template(category: categories::UTILITY, components: [body, carousel]) }
        .to raise_error(ActiveModel::ValidationError, /CAROUSEL is only supported on MARKETING/)
    end

    it "requires components" do
      expect { template(components: []) }
        .to raise_error(ActiveModel::ValidationError, /Components can't be blank/)
    end
  end

  describe "an authentication template" do
    it "serializes the flag-based component shape" do
      result = described_class.new(
        name: "auth_code", languages: %w[en_US es_ES], category: categories::AUTHENTICATION,
        components: [
          { type: :body, add_security_recommendation: true },
          { type: :footer, code_expiration_minutes: 15 },
          { type: :buttons, buttons: [{ type: :otp, otp_type: "COPY_CODE" }] },
        ]
      ).serialize

      expect(result[:languages]).to eq(%w[en_US es_ES])
      expect(result[:components]).to eq([
        { type: "BODY", add_security_recommendation: true },
        { type: "FOOTER", code_expiration_minutes: 15 },
        { type: "BUTTONS", buttons: [{ type: "OTP", otp_type: "COPY_CODE" }] },
      ])
    end
  end
end

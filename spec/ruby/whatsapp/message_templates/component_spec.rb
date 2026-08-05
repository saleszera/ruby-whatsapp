# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Component do
  describe ".build" do
    it "resolves every registered type to its class" do
      expect(described_class.build(type: :header, format: "LOCATION")).to be_a(described_class::Header)
      expect(described_class.build(type: :body, text: "Hi")).to be_a(described_class::Body)
      expect(described_class.build(type: :footer, text: "Bye")).to be_a(described_class::Footer)
      expect(described_class.build(type: :buttons, buttons: [{ type: :quick_reply, text: "Stop" }]))
        .to be_a(described_class::Buttons)
      expect(described_class.build(type: :limited_time_offer, text: "Offer!"))
        .to be_a(described_class::LimitedTimeOffer)
    end

    it "accepts Meta's uppercase wire casing" do
      expect(described_class.build(type: "BODY", text: "Hi")).to be_a(described_class::Body)
    end

    it "raises for an unknown type" do
      expect { described_class.build(type: :hologram) }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /Unknown component type/)
    end

    it "never resolves an arbitrary constant" do
      expect { described_class.build(type: "Object") }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /Unknown component type/)
    end

    it "threads the parameter format into the built component" do
      component = described_class.build(
        type: :body, text: "Hi {{name}}", example: { name: "Pablo" },
        parameter_format: Whatsapp::MessageTemplates::ParameterFormats::NAMED
      )

      expect(component.serialize[:example]).to eq(
        body_text_named_params: [{ param_name: "name", example: "Pablo" }]
      )
    end
  end

  describe ".serialize" do
    it "builds and serializes in one step" do
      expect(described_class.serialize(type: :footer, text: "Bye")).to eq(type: "FOOTER", text: "Bye")
    end
  end

  describe "TYPES" do
    it "is frozen so the registry cannot be mutated at runtime" do
      expect(described_class::TYPES).to be_frozen
    end

    it "registers only the component types with a published schema" do
      expect(described_class::TYPES.keys)
        .to contain_exactly(:header, :body, :footer, :buttons, :carousel, :limited_time_offer)
    end
  end
end

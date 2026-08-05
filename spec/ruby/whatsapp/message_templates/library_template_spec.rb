# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::LibraryTemplate do
  let(:categories) { Whatsapp::MessageTemplates::Categories }

  def library_template(**overrides)
    described_class.new(
      name: "my_delivery_update", language: "en_US", category: categories::UTILITY,
      library_template_name: "delivery_update_1",
      **overrides
    )
  end

  describe "#serialize" do
    it "emits the documented library clone payload" do
      expect(library_template.serialize).to eq(
        name: "my_delivery_update",
        language: "en_US",
        category: "UTILITY",
        library_template_name: "delivery_update_1"
      )
    end

    it "never emits a components key, since library content is fixed" do
      expect(library_template.serialize).not_to have_key(:components)
    end

    it "includes body inputs when given" do
      result = library_template(
        library_template_body_inputs: { add_contact_number: true, add_track_package_link: true }
      ).serialize

      expect(result[:library_template_body_inputs]).to eq(add_contact_number: true, add_track_package_link: true)
    end

    it "includes button inputs when given" do
      result = library_template(
        library_template_button_inputs: [
          { type: "URL", url: { base_url: "https://x.test/{{1}}", url_suffix_example: "https://x.test/demo" } },
          { type: "PHONE_NUMBER", phone_number: "+16315551010" },
        ]
      ).serialize

      expect(result[:library_template_button_inputs]).to eq([
        { type: "URL", url: { base_url: "https://x.test/{{1}}", url_suffix_example: "https://x.test/demo" } },
        { type: "PHONE_NUMBER", phone_number: "+16315551010" },
      ])
    end
  end

  describe "validations" do
    it "requires a library_template_name" do
      expect { library_template(library_template_name: nil) }
        .to raise_error(ActiveModel::ValidationError, /Library template name can't be blank/)
    end

    it "applies the same name rules as a normal template" do
      expect { library_template(name: "My Delivery Update") }
        .to raise_error(ActiveModel::ValidationError, /lowercase alphanumeric/)
    end

    it "requires a language" do
      expect { library_template(language: nil) }
        .to raise_error(ActiveModel::ValidationError, /Language can't be blank/)
    end

    it "rejects an unsupported language code" do
      expect { library_template(language: "kl_KL") }
        .to raise_error(ActiveModel::ValidationError, /not a valid WhatsApp language code/)
    end

    it "requires a category" do
      expect { library_template(category: nil) }
        .to raise_error(ActiveModel::ValidationError, /Category can't be blank/)
    end
  end
end

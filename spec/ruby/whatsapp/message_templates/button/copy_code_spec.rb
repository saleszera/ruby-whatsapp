# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates::Button::CopyCode do
  describe "#serialize" do
    it "emits the wire type and a scalar example, with no label" do
      expect(described_class.new(example: "250FF").serialize).to eq(type: "COPY_CODE", example: "250FF")
    end
  end

  describe "validations" do
    it "requires an example" do
      expect { described_class.new(example: nil) }
        .to raise_error(ActiveModel::ValidationError, /Example can't be blank/)
    end

    it "accepts an example at the 20 character limit" do
      expect { described_class.new(example: "a" * 20) }.not_to raise_error
    end

    it "rejects an example over 20 characters" do
      expect { described_class.new(example: "a" * 21) }
        .to raise_error(ActiveModel::ValidationError, /Example is too long/)
    end

    it "rejects a label, which Meta supplies itself" do
      expect { described_class.new(example: "250FF", text: "Copy code") }
        .to raise_error(ActiveModel::ValidationError, /cannot be set/)
    end
  end
end

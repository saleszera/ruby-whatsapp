# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Interactive::ListButtons do
  let(:coffee) { { title: "Coffee", rows: [{ id: "espresso", title: "Espresso" }] } }
  let(:tea) { { title: "Tea", rows: [{ id: "green", title: "Green tea" }] } }
  let(:untitled) { { rows: [{ id: "water", title: "Water" }] } }

  describe "#initialize" do
    it "is valid with one titled section" do
      expect { described_class.new(button: "Menu", sections: [coffee]) }.not_to raise_error
    end

    it "is valid with one untitled section" do
      expect { described_class.new(button: "Menu", sections: [untitled]) }.not_to raise_error
    end

    it "is valid with several sections that all have titles" do
      expect { described_class.new(button: "Menu", sections: [coffee, tea]) }.not_to raise_error
    end

    it "requires every section to have a title when there is more than one" do
      expect { described_class.new(button: "Menu", sections: [coffee, untitled]) }
        .to raise_error(ActiveModel::ValidationError,
          /Sections must each have a title when there is more than one section/)
    end

    it "counts a blank title as missing when there is more than one section" do
      expect { described_class.new(button: "Menu", sections: [coffee, untitled.merge(title: " ")]) }
        .to raise_error(ActiveModel::ValidationError, /Sections must each have a title/)
    end

    it "requires a button" do
      expect { described_class.new(button: nil, sections: [coffee]) }
        .to raise_error(ActiveModel::ValidationError, /Button can't be blank/)
    end

    it "rejects a button longer than 20 characters" do
      expect { described_class.new(button: "a" * 21, sections: [coffee]) }
        .to raise_error(ActiveModel::ValidationError, /Button is too long \(maximum is 20 characters\)/)
    end

    it "requires at least one section" do
      expect { described_class.new(button: "Menu", sections: []) }
        .to raise_error(ActiveModel::ValidationError, /Sections can't be blank/)
    end

    it "rejects more than 10 sections" do
      eleven = Array.new(11) { |index| { title: "Section #{index}", rows: [{ id: "r#{index}", title: "Row" }] } }

      expect { described_class.new(button: "Menu", sections: eleven) }
        .to raise_error(ActiveModel::ValidationError, /Sections is too long \(maximum is 10/)
    end
  end

  describe "#serialize" do
    it "serializes a single untitled section without a title key" do
      expect(described_class.new(button: "Menu", sections: [untitled]).serialize)
        .to eq(button: "Menu", sections: [{ rows: [{ id: "water", title: "Water" }] }])
    end

    it "serializes every section's title when there are several" do
      expect(described_class.new(button: "Menu", sections: [coffee, tea]).serialize)
        .to eq(button: "Menu", sections: [
          { title: "Coffee", rows: [{ id: "espresso", title: "Espresso" }] },
          { title: "Tea", rows: [{ id: "green", title: "Green tea" }] },
        ])
    end

    it "still enforces the section title length" do
      expect { described_class.serialize(button: "Menu", sections: [coffee.merge(title: "a" * 25)]) }
        .to raise_error(ActiveModel::ValidationError, /Title is too long \(maximum is 24 characters\)/)
    end
  end
end

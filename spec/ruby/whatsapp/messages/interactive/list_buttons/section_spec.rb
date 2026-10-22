# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Interactive::ListButtons::Section do
  let(:rows) { [{ id: "espresso", title: "Espresso" }] }

  describe "#initialize" do
    it "is valid with a title" do
      expect { described_class.new(title: "Coffee", rows:) }.not_to raise_error
    end

    # Meta requires a section title only when the list has more than one section — a rule
    # Section cannot see on its own, so ListButtons owns it.
    it "is valid without a title" do
      expect { described_class.new(rows:) }.not_to raise_error
    end

    it "accepts a title of exactly 24 characters" do
      expect { described_class.new(title: "a" * 24, rows:) }.not_to raise_error
    end

    it "rejects a title longer than 24 characters" do
      expect { described_class.new(title: "a" * 25, rows:) }
        .to raise_error(ActiveModel::ValidationError, /Title is too long \(maximum is 24 characters\)/)
    end

    it "requires rows" do
      expect { described_class.new(title: "Coffee", rows: []) }
        .to raise_error(ActiveModel::ValidationError, /Rows can't be blank/)
    end

    it "rejects more than 10 rows" do
      eleven = Array.new(11) { |index| { id: "row-#{index}", title: "Row #{index}" } }

      expect { described_class.new(title: "Coffee", rows: eleven) }
        .to raise_error(ActiveModel::ValidationError, /Rows is too long \(maximum is 10/)
    end
  end

  describe "#title" do
    it "keeps a given title" do
      expect(described_class.new(title: "Coffee", rows:).title).to eq("Coffee")
    end

    it "treats a blank title as absent" do
      expect(described_class.new(title: "", rows:).title).to be_nil
      expect(described_class.new(title: "   ", rows:).title).to be_nil
    end
  end

  describe "#serialize" do
    it "includes the title when given" do
      expect(described_class.new(title: "Coffee", rows:).serialize)
        .to eq(title: "Coffee", rows: [{ id: "espresso", title: "Espresso" }])
    end

    it "omits the title key when none is given" do
      expect(described_class.new(rows:).serialize)
        .to eq(rows: [{ id: "espresso", title: "Espresso" }])
    end

    # Sending `title: ""` would put an empty heading on the list rather than none.
    it "omits the title key when the title is blank" do
      expect(described_class.new(title: "", rows:).serialize).not_to have_key(:title)
    end
  end

  describe ".serialize" do
    it "builds and serializes in one call, without a title" do
      expect(described_class.serialize(rows:)).to eq(rows: [{ id: "espresso", title: "Espresso" }])
    end
  end
end

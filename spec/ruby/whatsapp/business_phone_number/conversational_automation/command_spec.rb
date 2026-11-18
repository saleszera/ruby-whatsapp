# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Command do
  describe "#serialize" do
    it "sends both documented fields" do
      command = described_class.new(command_name: "tickets", command_description: "Book flight tickets")

      expect(command.serialize).to eq({ command_name: "tickets", command_description: "Book flight tickets" })
    end
  end

  describe "validation" do
    it "builds a valid command" do
      expect { described_class.new(command_name: "tickets", command_description: "Book flight tickets") }
        .not_to raise_error
    end

    it "requires a command_name" do
      expect { described_class.new(command_name: nil, command_description: "Book") }
        .to raise_error(ActiveModel::ValidationError, /Command name can't be blank/)
    end

    it "rejects a blank command_name" do
      expect { described_class.new(command_name: "  ", command_description: "Book") }
        .to raise_error(ActiveModel::ValidationError, /Command name can't be blank/)
    end

    it "requires a command_description" do
      expect { described_class.new(command_name: "tickets", command_description: nil) }
        .to raise_error(ActiveModel::ValidationError, /Command description can't be blank/)
    end

    it "rejects a command_name longer than 32 characters" do
      expect { described_class.new(command_name: "a" * 33, command_description: "Book") }
        .to raise_error(ActiveModel::ValidationError, /Command name is too long \(maximum is 32 characters\)/)
    end

    it "accepts a command_name of exactly 32 characters" do
      expect { described_class.new(command_name: "a" * 32, command_description: "Book") }.not_to raise_error
    end

    it "rejects a command_description longer than 256 characters" do
      expect { described_class.new(command_name: "tickets", command_description: "a" * 257) }
        .to raise_error(ActiveModel::ValidationError, /Command description is too long \(maximum is 256 characters\)/)
    end

    it "accepts a command_description of exactly 256 characters" do
      expect { described_class.new(command_name: "tickets", command_description: "a" * 256) }.not_to raise_error
    end

    it "rejects a command_name with a leading slash, which Meta adds itself" do
      expect { described_class.new(command_name: "/tickets", command_description: "Book") }
        .to raise_error(ActiveModel::ValidationError, %r{Command name must not start with "/"})
    end

    it "accepts a slash that is not leading" do
      expect { described_class.new(command_name: "a/b", command_description: "Book") }.not_to raise_error
    end

    it "rejects an emoji in command_name" do
      expect { described_class.new(command_name: "tickets✈️", command_description: "Book") }
        .to raise_error(ActiveModel::ValidationError, /Command name must not contain emoji/)
    end

    it "rejects an emoji in command_description" do
      expect { described_class.new(command_name: "tickets", command_description: "Book 👋") }
        .to raise_error(ActiveModel::ValidationError, /Command description must not contain emoji/)
    end

    it "rejects a non-string command_name without raising a NoMethodError" do
      expect { described_class.new(command_name: 42, command_description: "Book") }
        .to raise_error(ActiveModel::ValidationError, /Command name must be a String/)
    end

    it "rejects a non-string command_description without raising a NoMethodError" do
      expect { described_class.new(command_name: "tickets", command_description: %w[Book]) }
        .to raise_error(ActiveModel::ValidationError, /Command description must be a String/)
    end
  end
end

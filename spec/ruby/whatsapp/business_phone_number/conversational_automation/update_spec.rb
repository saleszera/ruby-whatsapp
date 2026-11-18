# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Update do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/conversational_automation" }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:tickets) { { command_name: "tickets", command_description: "Book flight tickets" } }
  let(:hotel) { { command_name: "hotel", command_description: "Book hotel" } }

  describe "#serialize" do
    it "sends every field when all are given" do
      result = described_class.new(
        enable_welcome_message: true, prompts: ["Book a flight", "Plan a vacation"], commands: [tickets, hotel]
      ).serialize

      expect(result).to eq({
        enable_welcome_message: true,
        prompts: ["Book a flight", "Plan a vacation"],
        commands: [tickets, hotel],
      })
    end

    it "compacts away every omitted field rather than sending null" do
      expect(described_class.new(prompts: ["Book a flight"]).serialize).to eq({ prompts: ["Book a flight"] })
    end

    it "sends enable_welcome_message: false through, since that is how the welcome message is turned off" do
      expect(described_class.new(enable_welcome_message: false).serialize).to eq({ enable_welcome_message: false })
    end

    it "sends empty arrays through, since that is how the lists are cleared" do
      expect(described_class.new(prompts: [], commands: []).serialize).to eq({ prompts: [], commands: [] })
    end

    it "accepts Command instances" do
      command = Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Command.new(**tickets)

      expect(described_class.new(commands: [command]).serialize).to eq({ commands: [tickets] })
    end

    it "accepts string-keyed hashes, so a list read by Get can be sent straight back" do
      commands = [{ "command_name" => "tickets", "command_description" => "Book flight tickets" }]

      expect(described_class.new(commands:).serialize).to eq({ commands: [tickets] })
    end
  end

  describe "validation" do
    it "requires at least one attribute" do
      expect { described_class.new }.to raise_error(
        ActiveModel::ValidationError, /at least one of enable_welcome_message, prompts, commands must be provided/
      )
    end

    it "rejects a non-boolean enable_welcome_message rather than coercing a truthy value" do
      expect { described_class.new(enable_welcome_message: "true") }
        .to raise_error(ActiveModel::ValidationError, /Enable welcome message must be true or false/)
    end

    context "with prompts" do
      it "accepts up to 4 prompts" do
        expect { described_class.new(prompts: %w[a b c d]) }.not_to raise_error
      end

      it "rejects more than 4 prompts" do
        expect { described_class.new(prompts: %w[a b c d e]) }
          .to raise_error(ActiveModel::ValidationError, /Prompts accepts at most 4 entries/)
      end

      it "rejects a prompt longer than 80 characters" do
        expect { described_class.new(prompts: ["a" * 81]) }
          .to raise_error(ActiveModel::ValidationError,
            /Prompts entry at index 0 is too long \(maximum is 80 characters\)/)
      end

      it "accepts a prompt of exactly 80 characters" do
        expect { described_class.new(prompts: ["a" * 80]) }.not_to raise_error
      end

      it "rejects a blank prompt" do
        expect { described_class.new(prompts: ["Book a flight", " "]) }
          .to raise_error(ActiveModel::ValidationError, /Prompts entry at index 1 can't be blank/)
      end

      it "rejects a prompt containing an emoji" do
        expect { described_class.new(prompts: ["Plan a trip ✈️"]) }
          .to raise_error(ActiveModel::ValidationError, /Prompts entry at index 0 must not contain emoji/)
      end

      it "rejects a non-string prompt" do
        expect { described_class.new(prompts: [42]) }
          .to raise_error(ActiveModel::ValidationError, /Prompts entry at index 0 must be a String/)
      end

      it "rejects prompts that are not an Array" do
        expect { described_class.new(prompts: "Book a flight") }
          .to raise_error(ActiveModel::ValidationError, /Prompts must be an Array/)
      end
    end

    context "with commands" do
      it "accepts up to 30 commands" do
        commands = Array.new(30) { |index| { command_name: "cmd#{index}", command_description: "Do #{index}" } }

        expect { described_class.new(commands:) }.not_to raise_error
      end

      it "rejects more than 30 commands" do
        commands = Array.new(31) { |index| { command_name: "cmd#{index}", command_description: "Do #{index}" } }

        expect { described_class.new(commands:) }
          .to raise_error(ActiveModel::ValidationError, /Commands accepts at most 30 entries/)
      end

      it "reports an invalid command on :commands, naming its index" do
        commands = [tickets, { command_name: "/hotel", command_description: "Book hotel" }]

        expect { described_class.new(commands:) }.to raise_error(
          ActiveModel::ValidationError,
          %r{Commands contain an invalid command at index 1: Command name must not start with "/"}
        )
      end

      it "reports a command missing a keyword instead of raising ArgumentError" do
        expect { described_class.new(commands: [{ command_name: "tickets" }]) }.to raise_error(
          ActiveModel::ValidationError, /invalid command at index 0: missing keyword: :command_description/
        )
      end

      it "reports an unknown keyword instead of raising ArgumentError" do
        expect { described_class.new(commands: [tickets.merge(emoji: "x")]) }
          .to raise_error(ActiveModel::ValidationError, /invalid command at index 0: unknown keyword: :emoji/)
      end

      it "reports a command that is not a Hash instead of raising TypeError" do
        expect { described_class.new(commands: ["tickets"]) }
          .to raise_error(ActiveModel::ValidationError, /invalid command at index 0/)
      end

      it "rejects duplicate command names" do
        expect { described_class.new(commands: [tickets, tickets.merge(command_description: "Other")]) }
          .to raise_error(ActiveModel::ValidationError,
            /Commands must have unique command names \(duplicated: tickets\)/)
      end

      it "rejects commands that are not an Array" do
        expect { described_class.new(commands: tickets) }
          .to raise_error(ActiveModel::ValidationError, /Commands must be an Array/)
      end
    end
  end

  describe ".call" do
    it "posts the payload to the phone number's conversational_automation edge" do
      stub = stub_request(:post, edge)
        .with(
          headers: { "Authorization" => "Bearer TEST_TOKEN" },
          body: { enable_welcome_message: true, prompts: ["Book a flight"], commands: [tickets] }.to_json
        )
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      result = described_class.call(enable_welcome_message: true, prompts: ["Book a flight"], commands: [tickets])

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Response)
      expect(result.success).to be(true)
      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER/conversational_automation")
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(prompts: [], client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(prompts: [], client:) }.to raise_error(
        Whatsapp::BusinessPhoneNumber::Error,
        "phone_id is required for the conversational_automation edge; " \
          "set it via Whatsapp.configure or Client.new(phone_id:)"
      )
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 422, headers: json,
        body: { error: { message: "Phone number must be verified", code: 100 } }.to_json
      )

      expect { described_class.call(prompts: ["Book a flight"]) }.to raise_error(
        Whatsapp::BusinessPhoneNumber::Error,
        /Failed to update conversational automation.*Phone number must be verified/
      )
    end

    it "reports an unsuccessful update" do
      stub_request(:post, edge).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(described_class.call(prompts: []).success).to be(false)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:post, edge).to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(described_class.call(prompts: []).success).to be(true)
    end

    it "raises a validation error before making any request" do
      expect { described_class.call(prompts: %w[a b c d e]) }.to raise_error(ActiveModel::ValidationError)
      expect(a_request(:post, edge)).not_to have_been_made
    end
  end
end

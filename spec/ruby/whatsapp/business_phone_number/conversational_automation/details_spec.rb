# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::ConversationalAutomation::Details do
  describe ".deserialize" do
    let(:commands) do
      [
        { "command_name" => "tickets", "command_description" => "Book flight tickets" },
        { "command_name" => "hotel", "command_description" => "Book hotel" },
      ]
    end

    it "unwraps the conversational_automation envelope" do
      details = described_class.deserialize(
        "conversational_automation" => {
          "enable_welcome_message" => true,
          "prompts" => ["Find the best hotels in the area", "Find deals on rental cars"],
          "commands" => commands,
        },
        "id" => "123456"
      )

      expect(details.id).to eq("123456")
      expect(details.enable_welcome_message).to be(true)
      expect(details.prompts).to eq(["Find the best hotels in the area", "Find deals on rental cars"])
      expect(details.commands).to eq(commands)
    end

    it "keeps commands as Meta sent them, without running write-side validation" do
      oversized = [{ "command_name" => "a" * 40, "command_description" => "Book" }]

      details = described_class.deserialize("conversational_automation" => { "commands" => oversized })

      expect(details.commands).to eq(oversized)
    end

    it "defaults the lists to empty when Meta omits them" do
      details = described_class.deserialize("conversational_automation" => {}, "id" => "123456")

      expect(details.prompts).to eq([])
      expect(details.commands).to eq([])
      expect(details.enable_welcome_message).to be_nil
    end

    it "tolerates a body with no conversational_automation key" do
      details = described_class.deserialize("id" => "123456")

      expect(details.id).to eq("123456")
      expect(details.prompts).to eq([])
    end

    it "tolerates a nil body" do
      details = described_class.deserialize(nil)

      expect(details.id).to be_nil
      expect(details.commands).to eq([])
    end
  end

  describe "#welcome_message_enabled?" do
    it "is true only for a literal true" do
      expect(described_class.new(enable_welcome_message: true).welcome_message_enabled?).to be(true)
    end

    it "is false when disabled" do
      expect(described_class.new(enable_welcome_message: false).welcome_message_enabled?).to be(false)
    end

    it "is false when Meta omits the field" do
      expect(described_class.new.welcome_message_enabled?).to be(false)
    end

    it "is false for a truthy non-boolean" do
      expect(described_class.new(enable_welcome_message: "true").welcome_message_enabled?).to be(false)
    end
  end
end

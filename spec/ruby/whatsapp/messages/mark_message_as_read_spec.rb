# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::MarkMessageAsRead do
  let(:message_id) { "wamid.HBgLMTY1MDM4Nzk0MzkVAgARGBJDQjZCMzlEQUE4OTJBMTE4RTUA" }

  describe "validation" do
    it "is valid with a message_id" do
      expect { described_class.new(message_id:) }.not_to raise_error
    end

    it "raises when message_id is missing" do
      expect { described_class.new(message_id: nil) }
        .to raise_error(ActiveModel::ValidationError, /Message can't be blank/)
    end
  end

  describe "#serialize" do
    it "builds the flat status-update payload with no recipient or type envelope" do
      serialized = described_class.new(message_id:).serialize

      expect(serialized).to eq(
        messaging_product: "whatsapp",
        status: "read",
        message_id:
      )
    end
  end
end

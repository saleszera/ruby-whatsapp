# frozen_string_literal: true

module Whatsapp
  class Messages
    # Reaction messages are emoji-reactions applied to a WhatsApp message you have received.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/reaction-messages
    class Reaction < Base
      module Defaults
        TYPE = "reaction"
      end

      # Exactly one user-perceived character (grapheme cluster) that is an emoji: any
      # cluster containing a pictographic code point (which covers skin tones, ZWJ
      # sequences and variation selectors), a regional-indicator flag pair, or a keycap.
      # `\p{Emoji}` alone is not enough — it also matches the ASCII digits, `#` and `*`.
      EMOJI_PATTERN = /\A(?=\X\z)(?:.*\p{Extended_Pictographic}.*|\p{Regional_Indicator}{2}|[0-9#*]\uFE0F?\u20E3)\z/m

      # @!attribute [rw] message_id
      #   @return [String]
      attr_accessor :message_id

      # @!attribute [rw] emoji
      #   @return [String]
      attr_accessor :emoji

      validates :message_id, presence: true
      validate :validate_emoji

      # @param message_id [String] The ID of the message being reacted to.
      # @param emoji [String] The emoji used for the reaction.
      # @param kwargs [Hash] Additional keyword arguments.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(message_id:, emoji:, **)
        super(**)

        @message_id = message_id
        @emoji = emoji

        validate!
      end

      # Serializes the reaction message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized reaction message.
      def serialize
        envelope(type: Defaults::TYPE, reaction: { message_id:, emoji: })
      end

    private

      # An empty string is allowed, to remove a previously sent reaction. (Meta's
      # reaction page does not currently describe removal; this keeps the behavior the
      # gem has always documented.)
      # @return [void]
      def validate_emoji
        return errors.add(:emoji, :blank, message: "can't be nil") if emoji.nil?
        return if emoji.empty? || emoji.match?(EMOJI_PATTERN)

        errors.add(:emoji, :invalid, message: "must be a single emoji")
      end
    end
  end
end

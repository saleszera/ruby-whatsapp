# frozen_string_literal: true

module Whatsapp
  class Messages
    # Reaction messages are emoji-reactions applied to a WhatsApp message you have received.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/reaction-messages
    class Reaction < Base
      module Defaults
        TYPE = "reaction"
      end

      # Exactly one user-perceived character (grapheme cluster) that is an emoji: a cluster
      # starting with an emoji pictograph (which covers skin tones, ZWJ sequences, variation
      # selectors and tag flags), a regional-indicator flag pair, or a keycap. Neither
      # property is enough alone: `\p{Emoji}` also matches the ASCII digits, `#` and `*`, and
      # `\p{Extended_Pictographic}` also matches non-emoji symbols and code points Unicode
      # reserves for future emoji, such as U+2388 and U+1F000.
      EMOJI_PATTERN = /
        \A(?=\X\z)                                  # exactly one grapheme cluster
        (?:
          [\p{Emoji}&&\p{Extended_Pictographic}].*  # an emoji pictograph and its modifiers
          | \p{Regional_Indicator}{2}               # a flag
          | [0-9\#*]\uFE0F?\u20E3                   # a keycap
        )\z
      /xm

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

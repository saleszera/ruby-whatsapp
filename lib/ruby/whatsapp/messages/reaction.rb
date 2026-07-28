# frozen_string_literal: true

module Whatsapp
  class Messages
    # Reaction messages are emoji-reactions applied to a WhatsApp message you have received.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/reaction-messages
    class Reaction < Base
      module Defaults
        TYPE = "reaction"
      end

      # @!attribute [rw] message_id
      #   @return [String]
      attr_accessor :message_id

      # @!attribute [rw] emoji
      #   @return [String]
      attr_accessor :emoji

      validates :message_id, presence: true
      validate :emoji_unicode

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

      # Validates that the emoji is a valid Unicode emoji character.
      # @return [void]
      # @raise [ActiveModel::ValidationError] if the emoji is not valid.
      def emoji_unicode
        if @emoji.nil?
          errors.add(:emoji, "can't be nil")
          return
        end

        # An empty string is valid: it removes a previously sent reaction.
        return if @emoji.empty?
        return if @emoji.match?(/\p{Emoji}/)

        errors.add(:emoji, "must be a valid emoji character")
      end
    end
  end
end

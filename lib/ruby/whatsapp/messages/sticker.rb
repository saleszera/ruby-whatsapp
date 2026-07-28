# frozen_string_literal: true

module Whatsapp
  class Messages
    # Sticker messages display animated or static sticker images in a WhatsApp message.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/sticker-messages
    class Sticker < Base
      module Defaults
        TYPE = "sticker"
      end

      # @!attribute [rw] id
      #   @return [String]
      attr_accessor :id

      # @!attribute [rw] link
      #   @return [String]
      attr_accessor :link

      validate :validate_id_or_link

      # @param id [String, nil] ID of the uploaded media asset.
      # @param link [String, nil] URL of a publicly hosted media asset. Prefer uploading via
      #   Media#upload and passing +id+ for better performance.
      # @param kwargs [Hash] Additional keyword arguments.
      #   @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(id: nil, link: nil, **)
        super(**)

        @id = id
        @link = link

        validate!
      end

      # Serializes the sticker message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized sticker message.
      def serialize
        envelope(type: Defaults::TYPE, sticker:)
      end

    private

      # Serializes the sticker information to a hash format.
      # @return [Hash] The serialized sticker information.
      def sticker
        {
          id:,
          link:,
        }.compact
      end

      # Validates that either id or link is present.
      # @return [void]
      def validate_id_or_link
        return if id.present? || link.present?

        errors.add(:base, "Either id or link must be present")
      end
    end
  end
end

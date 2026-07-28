# frozen_string_literal: true

module Whatsapp
  class Messages
    # Video messages display a thumbnail preview of a video with an optional caption.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/video-messages
    class Video < Base
      module Defaults
        TYPE = "video"
      end

      # @!attribute [rw] id
      #   @return [String, nil]
      attr_accessor :id

      # @!attribute [rw] link
      #   @return [String, nil]
      attr_accessor :link

      # @!attribute [rw] caption
      #   @return [String, nil]
      attr_accessor :caption

      validate :validate_id_or_link
      validates :caption, length: { maximum: 1024 }, allow_nil: true

      # @param id [String, nil] ID of the uploaded media asset.
      # @param link [String, nil] URL of the media asset hosted on your public server.
      # @param caption [String, nil] Video caption text (maximum 1024 characters).
      # @param kwargs [Hash] Additional keyword arguments.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(id: nil, link: nil, caption: nil, **)
        super(**)

        @id = id
        @link = link
        @caption = caption

        validate!
      end

      # Serializes the video message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized video message.
      def serialize
        envelope(type: Defaults::TYPE, video: video_payload)
      end

    private

      # @return [Hash] The serialized video payload.
      def video_payload
        {
          id:,
          link:,
          caption:,
        }.compact
      end

      # Validates that either id or link is present
      # @return [void]
      def validate_id_or_link
        return if id.present? || link.present?

        errors.add(:base, "Either id or link must be present")
      end
    end
  end
end

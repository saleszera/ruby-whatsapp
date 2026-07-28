# frozen_string_literal: true

module Whatsapp
  class Messages
    # Audio messages allow you to send an audio file to a WhatsApp user.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/audio-messages
    #
    # Audio messages do not support captions. To send audio you must either:
    #   - Upload the audio via Whatsapp::Media#upload to obtain a media_id, then pass it as `id`
    #   - Pass a publicly hosted URL as `link` (not recommended by Meta)
    class Audio < Base
      module Defaults
        TYPE = "audio"
      end

      # @!attribute [rw] id
      #   @return [String, nil]
      attr_accessor :id

      # @!attribute [rw] link
      #   @return [String, nil]
      attr_accessor :link

      validate :validate_id_or_link

      # @param id [String, nil] ID of the uploaded media asset (from Media#upload).
      # @param link [String, nil] URL of the audio file hosted on a public server.
      # @param kwargs [Hash] Additional keyword arguments passed to Base (:to).
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(id: nil, link: nil, **)
        super(**)

        @id = id
        @link = link

        validate!
      end

      # Serializes the audio message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized audio message.
      def serialize
        envelope(type: Defaults::TYPE, audio: audio_payload)
      end

    private

      # @return [Hash] The serialized audio payload.
      def audio_payload
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

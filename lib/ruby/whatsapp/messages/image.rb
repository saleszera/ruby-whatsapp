# frozen_string_literal: true

module Whatsapp
  class Messages
    # Image messages display an image with an optional caption.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/image-messages
    #
    # To send an image you must either:
    #   - Upload the image via Whatsapp::Media#upload to obtain a media_id, then pass it as `id`
    #   - Pass a publicly hosted URL as `link` (not recommended by Meta)
    class Image < Base
      module Defaults
        TYPE = "image"
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

      # @param id [String, nil] ID of the uploaded media asset (from Media#upload).
      # @param link [String, nil] URL of the image hosted on a public server.
      # @param caption [String, nil] Image caption text (maximum 1024 characters).
      # @param kwargs [Hash] Additional keyword arguments passed to Base (:to).
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(id: nil, link: nil, caption: nil, **)
        super(**)

        @id = id
        @link = link
        @caption = caption

        validate!
      end

      # Serializes the image message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized image message.
      def serialize
        envelope(type: Defaults::TYPE, image: image_payload)
      end

    private

      # @return [Hash] The serialized image payload.
      def image_payload
        {
          id:,
          link:,
          caption:,
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

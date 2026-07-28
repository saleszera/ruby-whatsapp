# frozen_string_literal: true

module Whatsapp
  class Messages
    # Document messages allow you to send a document file with an optional caption and custom filename.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/document-messages
    #
    # To send a document you must either:
    #   - Upload the document via Whatsapp::Media#upload to obtain a media_id, then pass it as `id`
    #   - Pass a publicly hosted URL as `link` (not recommended by Meta)
    class Document < Base
      module Defaults
        TYPE = "document"
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

      # @!attribute [rw] filename
      #   @return [String, nil]
      attr_accessor :filename

      validate :validate_id_or_link
      validates :caption, length: { maximum: 1024 }, allow_nil: true

      # @param id [String, nil] ID of the uploaded media asset (from Media#upload).
      # @param link [String, nil] URL of the document hosted on a public server.
      # @param caption [String, nil] Document caption text (maximum 1024 characters).
      # @param filename [String, nil] Custom filename displayed in the chat (e.g. "invoice.pdf").
      # @param kwargs [Hash] Additional keyword arguments passed to Base (:to).
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(id: nil, link: nil, caption: nil, filename: nil, **)
        super(**)

        @id = id
        @link = link
        @caption = caption
        @filename = filename

        validate!
      end

      # Serializes the document message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized document message.
      def serialize
        envelope(type: Defaults::TYPE, document: document_payload)
      end

    private

      # @return [Hash] The serialized document payload.
      def document_payload
        {
          id:,
          link:,
          caption:,
          filename:,
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

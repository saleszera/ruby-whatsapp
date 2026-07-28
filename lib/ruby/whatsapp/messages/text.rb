# frozen_string_literal: true

module Whatsapp
  class Messages
    # Text messages are messages containing only a text body and an optional link preview.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/text-messages
    class Text < Base
      module Defaults
        TYPE = "text"
      end

      # @!attribute [rw] body
      #   @return [String]
      attr_accessor :body

      # @!attribute [rw] preview_url
      #   @return [Boolean]
      attr_accessor :preview_url

      validates :body, presence: true, length: { maximum: 4096 }
      validates :preview_url, inclusion: { in: [true, false] }

      # @param body [String] The text of the message.
      # @param preview_url [Boolean] Whether to enable URL preview in the message.
      # @param kwargs [Hash] Additional keyword arguments.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(body:, preview_url: true, **)
        super(**)

        @body = body
        @preview_url = preview_url

        validate!
      end

      # Serializes the text message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized text message.
      def serialize
        envelope(type: Defaults::TYPE, text: { body:, preview_url: })
      end
    end
  end
end

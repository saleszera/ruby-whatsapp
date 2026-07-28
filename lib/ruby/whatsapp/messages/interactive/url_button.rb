# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      # Interactive call-to-action (CTA) URL button message. Maps a URL to a
      # button so the raw URL does not have to appear in the message body.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-cta-url-messages
      class UrlButton < Base
        module Defaults
          MAX_NAME_LENGTH = 20
          MAX_DISPLAY_TEXT_LENGTH = 20
        end

        # @!attribute [rw] name
        #   @return [String]
        attr_accessor :name

        # @!attribute [rw] display_text
        #   @return [String]
        attr_accessor :display_text

        # @!attribute [rw] url
        #   @return [String]
        attr_accessor :url

        validates :name, presence: true, length: { maximum: Defaults::MAX_NAME_LENGTH }
        validates :display_text, presence: true, length: { maximum: Defaults::MAX_DISPLAY_TEXT_LENGTH }

        # @param name [String] The name of the URL button.
        # @param display_text [String] The text displayed on the button.
        # @param url [String] The URL that the button links to.
        def initialize(name:, display_text:, url:)
          @name = name
          @display_text = display_text
          @url = url

          validate!
        end

        class << self
          # @return [Hash] Serialized representation of the URL button.
          def serialize(**url_button)
            new(**url_button).serialize
          end
        end

        # @return [Hash] Serialized representation of the URL button.
        def serialize
          {
            name:,
            parameters:,
          }
        end

      private

        # @return [Hash] Serialized parameters for the URL button.
        def parameters
          {
            display_text:,
            url:,
          }.compact
        end
      end
    end
  end
end

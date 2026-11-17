# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class MediaCarousel
        class Card
          # A button on a media carousel card. Meta documents only the quick-reply
          # kind in a card's `action.buttons`; a URL button is the card's `action` itself.
          # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-media-carousel-messages
          class Button
            include ActiveModel::Validations

            module Defaults
              BUTTON_TYPE = "quick_reply"
            end

            # @!attribute [rw] quick_reply
            #   @return [Hash]
            attr_accessor :quick_reply

            validates :quick_reply, presence: true

            # @param quick_reply [Hash] The quick reply content of the button (`id:`, `title:`).
            # @raise [ActiveModel::ValidationError] if validation fails.
            def initialize(quick_reply:)
              @quick_reply = quick_reply

              validate!
            end

            class << self
              # @return [Hash] Serialized representation of the Button.
              def serialize(quick_reply:)
                new(quick_reply:).serialize
              end
            end

            # @return [Hash] Serialized representation of the Button.
            def serialize
              {
                type: Defaults::BUTTON_TYPE,
                quick_reply: QuickReply.serialize(**quick_reply),
              }
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class MediaCarousel
        class Card
          class Button
            module Defaults
              BUTTON_TYPE = "quick_reply"
            end

            # @!attribute [rw] quick_reply
            #   @return [Hash]
            attr_accessor :quick_reply

            # @param quick_reply [Hash] The quick reply content of the button.
            def initialize(quick_reply:)
              @quick_reply = quick_reply
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
                quick_reply: serialized_quick_reply,
              }
            end

          private

            def serialized_quick_reply
              QuickReply.serialize(**quick_reply)
            end
          end
        end
      end
    end
  end
end

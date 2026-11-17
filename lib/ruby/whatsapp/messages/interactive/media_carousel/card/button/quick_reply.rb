# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class MediaCarousel
        class Card
          class Button
            # A quick-reply button on a media carousel card.
            # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/interactive-media-carousel-messages
            class QuickReply
              include ActiveModel::Validations

              module Defaults
                MAX_ID_LENGTH = 256
                MAX_TITLE_LENGTH = 20
              end

              # @!attribute [rw] id
              #   @return [String]
              attr_accessor :id

              # @!attribute [rw] title
              #   @return [String]
              attr_accessor :title

              validates :id, presence: true, length: { maximum: Defaults::MAX_ID_LENGTH }
              validates :title, presence: true, length: { maximum: Defaults::MAX_TITLE_LENGTH }

              # @param id [String] The ID of the quick reply button, returned in the reply webhook.
              # @param title [String] The label of the quick reply button.
              # @raise [ActiveModel::ValidationError] if validation fails.
              def initialize(id:, title:)
                @id = id
                @title = title

                validate!
              end

              class << self
                # @return [Hash] Serialized representation of the QuickReply.
                def serialize(id:, title:)
                  new(id:, title:).serialize
                end
              end

              # @return [Hash] Serialized representation of the QuickReply.
              def serialize
                {
                  id:,
                  title:,
                }
              end
            end
          end
        end
      end
    end
  end
end

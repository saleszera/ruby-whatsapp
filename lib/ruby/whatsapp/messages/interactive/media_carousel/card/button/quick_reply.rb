# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class MediaCarousel
        class Card
          class Button
            class QuickReply
              include ActiveModel::Validations

              # @!attribute [rw] id
              #   @return [String]
              attr_accessor :id

              # @!attribute [rw] title
              #   @return [String]
              attr_accessor :title

              validates :id, presence: true, length: { maximum: 20 }
              validates :title, presence: true, length: { maximum: 20 }

              # @param id [String] The ID of the quick reply button.
              # @param title [String] The title of the quick reply button.
              def initialize(id:, title:)
                @id = id
                @title = title
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

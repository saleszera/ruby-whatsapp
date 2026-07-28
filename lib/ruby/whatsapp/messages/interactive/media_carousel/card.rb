# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class MediaCarousel
        class Card
          include ActiveModel::Validations

          module Defaults
            TYPE = "cta_url"
          end

          # @!attribute [rw] card_index
          #   @return [Integer]
          attr_accessor :card_index

          # @!attribute [rw] header
          #   @return [Hash]
          attr_accessor :header

          # @!attribute [rw] body
          #   @return [String]
          attr_accessor :body

          # @!attribute [rw] action
          #   @return [Hash]
          attr_accessor :action

          # @!attribute [rw] buttons
          #   @return [Array<Hash>]
          attr_accessor :buttons

          validates :card_index, presence: true

          # @param card_index [Integer] The index of the card.
          # @param header [Hash] The header content of the card.
          # @param body [String] The body content of the card.
          # @param action [Hash] The action content of the card.
          def initialize(card_index:, header:, body:, action:, buttons:)
            @card_index = card_index
            @header = header
            @body = body
            @action = action
            @buttons = buttons

            validate!
          end

          class << self
            # @return [Hash] Serialized representation of the Card.
            def serialize(card_index:, header:, body:, action:, buttons:)
              new(card_index:, header:, body:, action:, buttons:).serialize
            end
          end

          # @return [Hash] Serialized representation of the Card.
          def serialize
            {
              card_index:,
              type: Defaults::TYPE,
              header: Whatsapp::Messages::Interactive::Header.serialize(**header),
              body: Whatsapp::Messages::Interactive::Body.serialize(body),
              action: Whatsapp::Messages::Interactive::UrlButton.serialize(**action),
              buttons: serialized_buttons,
            }
          end

        private

          def serialized_buttons
            buttons.map { |button| Button.serialize(**button) }
          end
        end
      end
    end
  end
end

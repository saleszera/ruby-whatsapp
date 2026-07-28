# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class ReplyButtons < Base
        module Defaults
          MAX_BUTTONS = 3
        end

        # @!attribute [rw] buttons
        #   @return [Array<Hash>]
        attr_accessor :buttons

        validates :buttons, presence: true, length: { maximum: Defaults::MAX_BUTTONS }

        # @param buttons [Array<Hash>] The buttons of the reply buttons.
        def initialize(buttons:)
          @buttons = buttons

          validate!
        end

        class << self
          # @return [Hash] Serialized representation of the ReplyButtons.
          def serialize(buttons:)
            new(buttons:).serialize
          end
        end

        # @return [Hash] Serialized representation of the ReplyButtons.
        def serialize
          {
            buttons: serialized_buttons,
          }
        end

      private

        # @return [Array<Hash>] Serialized buttons.
        def serialized_buttons
          buttons.map { |button| Button.serialize(**button) }
        end
      end
    end
  end
end

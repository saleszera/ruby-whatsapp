# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound sticker message.
      class Sticker < Media
        # @!attribute [rw] animated
        #   @return [Boolean, nil]
        attr_accessor :animated

        def initialize(animated: nil, **media_and_base_attributes)
          super(**media_and_base_attributes)

          @animated = animated
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Sticker]
          def deserialize(data)
            new(
              animated: data.dig("sticker", "animated"),
              **media_attributes(data, "sticker"),
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end

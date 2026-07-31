# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound video message.
      class Video < Media
        class << self
          # @param data [Hash] The raw message hash.
          # @return [Video]
          def deserialize(data)
            new(**media_attributes(data, "video"), **common_attributes(data))
          end
        end
      end
    end
  end
end

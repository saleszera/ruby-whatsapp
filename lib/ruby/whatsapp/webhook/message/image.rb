# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound image message.
      class Image < Media
        class << self
          # @param data [Hash] The raw message hash.
          # @return [Image]
          def deserialize(data)
            new(**media_attributes(data, "image"), **common_attributes(data))
          end
        end
      end
    end
  end
end

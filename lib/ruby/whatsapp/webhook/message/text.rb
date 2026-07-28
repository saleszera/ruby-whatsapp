# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound plain-text message.
      class Text < Base
        # @!attribute [rw] body
        #   @return [String, nil]
        attr_accessor :body

        def initialize(body:, **base_attributes)
          super(**base_attributes)

          @body = body
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Text]
          def deserialize(data)
            new(body: data.dig("text", "body"), **common_attributes(data))
          end
        end
      end
    end
  end
end

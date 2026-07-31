# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound tap on a template's quick-reply button.
      class Button < Base
        # @!attribute [rw] text
        #   @return [String, nil] The button's display text.
        attr_accessor :text

        # @!attribute [rw] payload
        #   @return [String, nil] The developer-defined payload configured on the template button.
        attr_accessor :payload

        def initialize(text:, payload:, **base_attributes)
          super(**base_attributes)

          @text = text
          @payload = payload
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Button]
          def deserialize(data)
            new(text: data.dig("button", "text"), payload: data.dig("button", "payload"), **common_attributes(data))
          end
        end
      end
    end
  end
end

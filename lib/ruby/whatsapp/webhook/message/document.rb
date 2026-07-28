# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound document message.
      class Document < Media
        # @!attribute [rw] filename
        #   @return [String, nil]
        attr_accessor :filename

        def initialize(filename: nil, **media_and_base_attributes)
          super(**media_and_base_attributes)

          @filename = filename
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Document]
          def deserialize(data)
            new(
              filename: data.dig("document", "filename"),
              **media_attributes(data, "document"),
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end

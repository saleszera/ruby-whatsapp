# frozen_string_literal: true

module Whatsapp
  class Messages
    class Response
      class Messages
        # @!attribute [rw] id
        #   @return [String]
        attr_accessor :id

        # @param id [String] The unique identifier of the message.
        def initialize(id:)
          @id = id
        end

        class << self
          # Deserializes a hash into a Messages::Response::Messages object.
          # @param data [Hash] The hash representation of the message response.
          #   @return [Messages::Response::Messages] The deserialized message response object.
          def deserialize(data)
            new(id: data["id"])
          end
        end
      end
    end
  end
end

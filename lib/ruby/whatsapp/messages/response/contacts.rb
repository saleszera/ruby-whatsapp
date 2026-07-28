# frozen_string_literal: true

module Whatsapp
  class Messages
    class Response
      class Contacts
        # @!attribute [rw] input
        #   @return [String]
        attr_accessor :input

        # @!attribute [rw] wa_id
        #   @return [String]
        attr_accessor :wa_id

        # @param input [String] The input value of the contact.
        # @param wa_id [String] The WhatsApp ID of the contact.
        def initialize(input:, wa_id:)
          @input = input
          @wa_id = wa_id
        end

        class << self
          # Deserializes a hash into a Messages::Response::Contacts object.
          # @param data [Hash] The hash representation of the contact response.
          #   @return [Messages::Response::Contacts] The deserialized contact response object.
          def deserialize(data)
            new(
              input: data["input"],
              wa_id: data["wa_id"]
            )
          end
        end
      end
    end
  end
end

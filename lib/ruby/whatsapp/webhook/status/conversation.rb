# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Status
      # The conversation window a status update was billed/attributed to.
      class Conversation
        # @!attribute [rw] id
        #   @return [String, nil]
        attr_accessor :id

        # @!attribute [rw] origin_type
        #   @return [String, nil] e.g. `"service"`, `"marketing"`, `"utility"`, `"authentication"`.
        attr_accessor :origin_type

        # @!attribute [rw] expiration_timestamp
        #   @return [String, nil]
        attr_accessor :expiration_timestamp

        def initialize(id:, origin_type:, expiration_timestamp: nil)
          @id = id
          @origin_type = origin_type
          @expiration_timestamp = expiration_timestamp
        end

        class << self
          # @param data [Hash] The raw `conversation` hash.
          # @return [Conversation]
          def deserialize(data)
            data ||= {}

            new(
              id: data["id"],
              origin_type: data.dig("origin", "type"),
              expiration_timestamp: data["expiration_timestamp"]
            )
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # Fallback for a message `type` not in {Message::MESSAGE_TYPES} — either a
      # type Meta added after this gem was released, or a message the Cloud API
      # itself couldn't process (carries an `errors[]` array in that case).
      class Unknown < Base
        # @!attribute [rw] raw
        #   @return [Hash] The full, untyped raw message hash.
        attr_accessor :raw

        # @!attribute [rw] errors
        #   @return [Array<Error>]
        attr_accessor :errors

        def initialize(raw:, errors:, **base_attributes)
          super(**base_attributes)

          @raw = raw
          @errors = errors
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Unknown]
          def deserialize(data)
            new(
              raw: data,
              errors: Array(data["errors"]).map { |error_data| Error.deserialize(error_data) },
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end

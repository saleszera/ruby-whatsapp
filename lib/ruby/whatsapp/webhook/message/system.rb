# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # A system notice, e.g. that the customer changed their phone number.
      class System < Base
        # @!attribute [rw] body
        #   @return [String, nil] Human-readable description of the change.
        attr_accessor :body

        # @!attribute [rw] identity
        #   @return [String, nil]
        attr_accessor :identity

        # @!attribute [rw] wa_id
        #   @return [String, nil] The customer's (possibly new) WhatsApp ID.
        attr_accessor :wa_id

        # @!attribute [rw] change_type
        #   @return [String, nil] e.g. `"customer_changed_number"`, `"customer_identity_changed"`.
        attr_accessor :change_type

        def initialize(body:, identity:, wa_id:, change_type:, **base_attributes)
          super(**base_attributes)

          @body = body
          @identity = identity
          @wa_id = wa_id
          @change_type = change_type
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [System]
          def deserialize(data)
            new(
              body: data.dig("system", "body"),
              identity: data.dig("system", "identity"),
              wa_id: data.dig("system", "wa_id"),
              change_type: data.dig("system", "type"),
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end

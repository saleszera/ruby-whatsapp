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

        # @!attribute [rw] user_id
        #   @return [String, nil] The customer's new business-scoped user ID (BSUID),
        #     set when the change was a `user_changed_user_id` event.
        attr_accessor :user_id

        # @!attribute [rw] parent_user_id
        #   @return [String, nil] The customer's new parent BSUID, present only when enrolled.
        attr_accessor :parent_user_id

        # @!attribute [rw] change_type
        #   @return [String, nil] e.g. `"customer_changed_number"`, `"user_changed_user_id"`.
        attr_accessor :change_type

        def initialize(
          change_type:,
          body: nil, identity: nil, wa_id: nil, user_id: nil, parent_user_id: nil,
          **base_attributes
        )
          super(**base_attributes)

          @body = body
          @identity = identity
          @wa_id = wa_id
          @user_id = user_id
          @parent_user_id = parent_user_id
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
              user_id: data.dig("system", "user_id"),
              parent_user_id: data.dig("system", "parent_user_id"),
              change_type: data.dig("system", "type"),
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end

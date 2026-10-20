# frozen_string_literal: true

module Whatsapp
  module Webhook
    class UserIdUpdate
      # A single `user_id_update[]` entry: one user's BSUID (and parent BSUID, if
      # enrolled) changed.
      class Entry
        # @!attribute [rw] wa_id
        #   @return [String, nil] The user's phone number, if available.
        attr_accessor :wa_id

        # @!attribute [rw] detail
        #   @return [String, nil] Human-readable description of the change.
        attr_accessor :detail

        # @!attribute [rw] user_id
        #   @return [IdChange, nil] The user's previous and current BSUID.
        attr_accessor :user_id

        # @!attribute [rw] parent_user_id
        #   @return [IdChange, nil] The user's previous and current parent BSUID,
        #     present only when enrolled.
        attr_accessor :parent_user_id

        # @!attribute [rw] timestamp
        #   @return [String, nil]
        attr_accessor :timestamp

        def initialize(timestamp:, wa_id: nil, detail: nil, user_id: nil, parent_user_id: nil)
          @wa_id = wa_id
          @detail = detail
          @user_id = user_id
          @parent_user_id = parent_user_id
          @timestamp = timestamp
        end

        class << self
          # @param data [Hash] A raw `user_id_update[]` entry.
          # @return [Entry]
          def deserialize(data)
            data ||= {}

            new(
              wa_id: data["wa_id"],
              detail: data["detail"],
              user_id: IdChange.deserialize(data["user_id"]),
              parent_user_id: IdChange.deserialize(data["parent_user_id"]),
              timestamp: data["timestamp"]
            )
          end
        end
      end
    end
  end
end

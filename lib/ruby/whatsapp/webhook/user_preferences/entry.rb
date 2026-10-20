# frozen_string_literal: true

module Whatsapp
  module Webhook
    class UserPreferences
      # A single `user_preferences[]` entry: one user changed one preference.
      class Entry
        # @!attribute [rw] wa_id
        #   @return [String, nil] The user's phone number, omitted once they adopt a
        #     username and it is no longer shareable. Fall back to {#user_id}.
        attr_accessor :wa_id

        # @!attribute [rw] user_id
        #   @return [String, nil] The user's business-scoped user ID (BSUID).
        attr_accessor :user_id

        # @!attribute [rw] parent_user_id
        #   @return [String, nil] The user's parent BSUID, present only when enrolled.
        attr_accessor :parent_user_id

        # @!attribute [rw] detail
        #   @return [String, nil] Human-readable description of the change.
        attr_accessor :detail

        # @!attribute [rw] category
        #   @return [String, nil] The preference category. `"marketing_messages"` is the
        #     only value Meta documents; kept a raw String, never validated on the way in,
        #     so a category added later still round-trips.
        attr_accessor :category

        # @!attribute [rw] value
        #   @return [String, nil] The preference itself, e.g. `"stop"` or `"resume"`. Note
        #     the name: this sits *inside* the change's own `value` hash, so the full path
        #     reads `change.value.preferences.first.value`. Meta's naming, not ours.
        attr_accessor :value

        # @!attribute [rw] timestamp
        #   @return [Integer, String, nil] Unix seconds. Meta's example sends a number
        #     here, unlike the string timestamps on `messages`, so it is passed through
        #     as-is rather than coerced.
        attr_accessor :timestamp

        def initialize(
          wa_id: nil, user_id: nil, parent_user_id: nil,
          detail: nil, category: nil, value: nil, timestamp: nil
        )
          @wa_id = wa_id
          @user_id = user_id
          @parent_user_id = parent_user_id
          @detail = detail
          @category = category
          @value = value
          @timestamp = timestamp
        end

        class << self
          # @param data [Hash, nil] A raw `user_preferences[]` entry.
          # @return [Entry]
          def deserialize(data)
            data ||= {}

            new(
              wa_id: data["wa_id"],
              user_id: data["user_id"],
              parent_user_id: data["parent_user_id"],
              detail: data["detail"],
              category: data["category"],
              value: data["value"],
              timestamp: data["timestamp"]
            )
          end
        end
      end
    end
  end
end

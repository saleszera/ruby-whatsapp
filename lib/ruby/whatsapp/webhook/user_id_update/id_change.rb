# frozen_string_literal: true

module Whatsapp
  module Webhook
    class UserIdUpdate
      # The `{previous, current}` shape shared by `user_id` and `parent_user_id` on a
      # `user_id_update[]` entry.
      class IdChange
        # @!attribute [rw] previous
        #   @return [String, nil]
        attr_accessor :previous

        # @!attribute [rw] current
        #   @return [String, nil]
        attr_accessor :current

        def initialize(previous:, current:)
          @previous = previous
          @current = current
        end

        class << self
          # @param data [Hash, nil] The raw `user_id` or `parent_user_id` hash.
          # @return [IdChange, nil] `nil` when the key is absent — an id change that did
          #   not happen is not a change from nothing to nothing.
          def deserialize(data)
            return if data.nil?

            new(previous: data["previous"], current: data["current"])
          end
        end
      end
    end
  end
end

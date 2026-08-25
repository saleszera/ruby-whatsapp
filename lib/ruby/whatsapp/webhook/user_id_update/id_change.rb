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
          # @return [IdChange]
          def deserialize(data)
            data ||= {}

            new(previous: data["previous"], current: data["current"])
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      # An inbound reply to an interactive message — a button tap (`button_reply`)
      # or a list row selection (`list_reply`).
      class Interactive < Base
        # @!attribute [rw] interactive_type
        #   @return [String, nil] Either `"button_reply"` or `"list_reply"`.
        attr_accessor :interactive_type

        # @!attribute [rw] reply_id
        #   @return [String, nil] The id of the tapped button/row.
        attr_accessor :reply_id

        # @!attribute [rw] title
        #   @return [String, nil]
        attr_accessor :title

        # @!attribute [rw] description
        #   @return [String, nil] Only present for `list_reply`.
        attr_accessor :description

        def initialize(interactive_type:, reply_id:, title:, description: nil, **base_attributes)
          super(**base_attributes)

          @interactive_type = interactive_type
          @reply_id = reply_id
          @title = title
          @description = description
        end

        class << self
          # @param data [Hash] The raw message hash.
          # @return [Interactive]
          def deserialize(data)
            interactive_type = data.dig("interactive", "type")
            reply = data.dig("interactive", interactive_type) || {}

            new(
              interactive_type:,
              reply_id: reply["id"],
              title: reply["title"],
              description: reply["description"],
              **common_attributes(data)
            )
          end
        end
      end
    end
  end
end

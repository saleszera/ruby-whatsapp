# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    module Response
      # The `summary` block of a template list.
      #
      # Worth reading rather than ignoring: `message_template_count` against
      # `message_template_limit` is the only way to see how close a WABA is to its
      # template cap — 250 for an unverified business portfolio, up to 6,000 for a
      # verified one with an approved display name. Hitting it turns every subsequent
      # create into an error.
      # Source: https://developers.facebook.com/docs/graph-api/reference/whats-app-business-account/message_templates/
      class Summary
        # @!attribute [rw] total_count
        #   @return [Integer, nil]
        attr_accessor :total_count

        # @!attribute [rw] message_template_count
        #   @return [Integer, nil] Templates currently on the account.
        attr_accessor :message_template_count

        # @!attribute [rw] message_template_limit
        #   @return [Integer, nil] The account's cap.
        attr_accessor :message_template_limit

        # @!attribute [rw] are_translations_complete
        #   @return [Boolean, nil]
        attr_accessor :are_translations_complete

        # @param total_count [Integer, nil]
        # @param message_template_count [Integer, nil]
        # @param message_template_limit [Integer, nil]
        # @param are_translations_complete [Boolean, nil]
        def initialize(total_count: nil, message_template_count: nil, message_template_limit: nil,
          are_translations_complete: nil)
          @total_count = total_count
          @message_template_count = message_template_count
          @message_template_limit = message_template_limit
          @are_translations_complete = are_translations_complete
        end

        class << self
          # @param data [Hash, nil] The raw `summary` object.
          # @return [Summary]
          def deserialize(data)
            data ||= {}

            new(
              total_count: data["total_count"],
              message_template_count: data["message_template_count"],
              message_template_limit: data["message_template_limit"],
              are_translations_complete: data["are_translations_complete"]
            )
          end
        end

        # How many more templates the account can hold.
        # @return [Integer, nil] nil when either figure is missing.
        def remaining
          return if message_template_limit.nil? || message_template_count.nil?

          message_template_limit - message_template_count
        end
      end
    end
  end
end

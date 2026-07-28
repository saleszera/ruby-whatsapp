# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Template category changes and re-categorization corrections.
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class TemplateCategoryUpdate
      # @!attribute [rw] message_template_id
      #   @return [Integer, nil]
      attr_accessor :message_template_id

      # @!attribute [rw] message_template_name
      #   @return [String, nil]
      attr_accessor :message_template_name

      # @!attribute [rw] message_template_language
      #   @return [String, nil]
      attr_accessor :message_template_language

      # @!attribute [rw] previous_category
      #   @return [String, nil]
      attr_accessor :previous_category

      # @!attribute [rw] new_category
      #   @return [String, nil]
      attr_accessor :new_category

      # @!attribute [rw] correct_category
      #   @return [String, nil]
      attr_accessor :correct_category

      def initialize(message_template_id:, message_template_name:, message_template_language:,
        previous_category:, new_category:, correct_category: nil)
        @message_template_id = message_template_id
        @message_template_name = message_template_name
        @message_template_language = message_template_language
        @previous_category = previous_category
        @new_category = new_category
        @correct_category = correct_category
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [TemplateCategoryUpdate]
        def deserialize(data)
          data ||= {}

          new(
            message_template_id: data["message_template_id"],
            message_template_name: data["message_template_name"],
            message_template_language: data["message_template_language"],
            previous_category: data["previous_category"],
            new_category: data["new_category"],
            correct_category: data["correct_category"]
          )
        end
      end
    end
  end
end

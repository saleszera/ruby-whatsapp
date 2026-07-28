# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Template quality score changes (e.g. green/yellow/red rating shifts based
    # on recipient feedback).
    #
    # Best-effort schema: Meta's public docs describe this field in one line with
    # no published JSON example. Validate against a real payload (App Dashboard
    # "send test payload") before relying on these attribute names in production.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/webhooks/overview
    class MessageTemplateQualityUpdate
      # @!attribute [rw] message_template_id
      #   @return [Integer, nil]
      attr_accessor :message_template_id

      # @!attribute [rw] message_template_name
      #   @return [String, nil]
      attr_accessor :message_template_name

      # @!attribute [rw] message_template_language
      #   @return [String, nil]
      attr_accessor :message_template_language

      # @!attribute [rw] previous_quality_score
      #   @return [String, nil] e.g. `"GREEN"`, `"YELLOW"`, `"RED"`.
      attr_accessor :previous_quality_score

      # @!attribute [rw] new_quality_score
      #   @return [String, nil]
      attr_accessor :new_quality_score

      def initialize(message_template_id:, message_template_name:, message_template_language:,
        previous_quality_score:, new_quality_score:)
        @message_template_id = message_template_id
        @message_template_name = message_template_name
        @message_template_language = message_template_language
        @previous_quality_score = previous_quality_score
        @new_quality_score = new_quality_score
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [MessageTemplateQualityUpdate]
        def deserialize(data)
          data ||= {}

          new(
            message_template_id: data["message_template_id"],
            message_template_name: data["message_template_name"],
            message_template_language: data["message_template_language"],
            previous_quality_score: data["previous_quality_score"],
            new_quality_score: data["new_quality_score"]
          )
        end
      end
    end
  end
end

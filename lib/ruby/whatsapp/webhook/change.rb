# frozen_string_literal: true

module Whatsapp
  module Webhook
    # A single `entry[].changes[]` item: `field` names which of Meta's ~19 documented
    # webhook notification types this is, `value` is the deserialized payload for it.
    #
    # `FIELDS` is populated incrementally as each field's value class is implemented
    # (see Whatsapp::Webhook::CLAUDE.md) — never `const_get` on the field name, which
    # comes straight from the internet; a field not yet in the registry falls back to
    # {UnknownField} rather than raising.
    class Change
      FIELDS = {
        messages: Messages,
        account_alerts: AccountAlerts,
        account_review_update: AccountReviewUpdate,
        account_update: AccountUpdate,
        automatic_events: AutomaticEvents,
        business_capability_update: BusinessCapabilityUpdate,
        history: History,
        message_template_components_update: MessageTemplateComponentsUpdate,
        message_template_quality_update: MessageTemplateQualityUpdate,
        message_template_status_update: MessageTemplateStatusUpdate,
        partner_solutions: PartnerSolutions,
        payment_configuration_update: PaymentConfigurationUpdate,
        phone_number_name_update: PhoneNumberNameUpdate,
        phone_number_quality_update: PhoneNumberQualityUpdate,
        security: Security,
        smb_app_state_sync: SmbAppStateSync,
        smb_message_echoes: SmbMessageEchoes,
        template_category_update: TemplateCategoryUpdate,
        user_preferences: UserPreferences,
      }.freeze

      # @!attribute [rw] field
      #   @return [String]
      attr_accessor :field

      # @!attribute [rw] value
      #   @return [Object] One of the classes registered in {FIELDS}, or {UnknownField}.
      attr_accessor :value

      def initialize(field:, value:)
        @field = field
        @value = value
      end

      class << self
        # @param data [Hash] A raw `changes[]` entry.
        # @return [Change]
        def deserialize(data)
          data ||= {}
          field = data["field"]
          klass = FIELDS.fetch(field.to_s.to_sym) { UnknownField }

          new(field:, value: klass.deserialize(data["value"]))
        end
      end
    end
  end
end

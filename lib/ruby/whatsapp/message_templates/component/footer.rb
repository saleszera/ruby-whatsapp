# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Component
      # The optional small-print line below the body. At most one per template.
      #
      # Two mutually exclusive shapes, mirroring {Body}:
      #
      #   standard       — `text` (60 chars, and no placeholders at all)
      #   authentication — `code_expiration_minutes`, which renders Meta's own
      #                    localised "This code expires in N minutes." Omit the footer
      #                    entirely to omit that notice.
      #
      # Forbidden altogether in limited-time-offer templates, which {Template} enforces.
      # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
      class Footer < Base
        module Defaults
          TYPE = "FOOTER"
          MAX_TEXT_LENGTH = 60
          CODE_EXPIRATION_RANGE = (1..90)
        end

        # @!attribute [rw] text
        #   @return [String, nil]
        attr_accessor :text

        # @!attribute [rw] code_expiration_minutes
        #   @return [Integer, nil] Authentication templates only.
        attr_accessor :code_expiration_minutes

        validate :validate_shape
        validate :validate_text
        validate :validate_code_expiration

        # @param text [String, nil] The footer text (max 60 characters, no placeholders).
        # @param code_expiration_minutes [Integer, nil] Authentication templates only;
        #   must be within 1..90. Mutually exclusive with `text`.
        # @param kwargs [Hash] Forwarded to {Base} (`parameter_format`).
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(text: nil, code_expiration_minutes: nil, **)
          super(**)

          @text = text
          @code_expiration_minutes = code_expiration_minutes

          validate!
        end

        # @return [Boolean] Whether this is the expiry-based authentication shape.
        def authentication?
          !code_expiration_minutes.nil?
        end

        # @return [Hash] The serialized component.
        def serialize
          return { type: Defaults::TYPE, code_expiration_minutes: } if authentication?

          { type: Defaults::TYPE, text: }
        end

      private

        # @return [void]
        def validate_shape
          if authentication? && !blank_value?(text)
            return errors.add(:text, "cannot be combined with code_expiration_minutes")
          end

          return unless blank_value?(text) && !authentication?

          errors.add(:base, "requires either text or code_expiration_minutes")
        end

        # @return [void]
        def validate_text
          return if authentication? || blank_value?(text)

          if text.length > Defaults::MAX_TEXT_LENGTH
            errors.add(:text, "is too long (maximum is #{Defaults::MAX_TEXT_LENGTH} characters)")
          end

          return if Placeholders.count(text).zero?

          errors.add(:text, "does not support placeholders")
        end

        # @return [void]
        def validate_code_expiration
          return unless authentication?
          return if code_expiration_minutes.is_a?(Integer) &&
            Defaults::CODE_EXPIRATION_RANGE.cover?(code_expiration_minutes)

          errors.add(:code_expiration_minutes, "must be in #{Defaults::CODE_EXPIRATION_RANGE}")
        end
      end
    end
  end
end

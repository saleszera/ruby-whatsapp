# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Component
      # The template's message text. The only component Meta requires.
      #
      # Two mutually exclusive shapes, hence the XOR validation:
      #
      #   standard       — `text` (1024 chars) with any number of placeholders, plus a
      #                    matching `example`
      #   authentication — no text at all. Meta supplies the fixed, localised string
      #                    "<VERIFICATION_CODE> is your verification code." and
      #                    `add_security_recommendation` only decides whether the
      #                    "do not share this code" line is appended.
      #
      # The tighter 600-character limit that applies inside a limited-time-offer
      # template is enforced by {Template}, which is the only object that can see
      # whether such a component is present.
      # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
      class Body < Base
        module Defaults
          TYPE = "BODY"
          MAX_TEXT_LENGTH = 1024
        end

        # @!attribute [rw] text
        #   @return [String, nil]
        attr_accessor :text

        # @!attribute [rw] example
        #   @return [Hash, nil] The serialized example payload.
        attr_accessor :example

        # @!attribute [rw] add_security_recommendation
        #   @return [Boolean, nil] Authentication templates only.
        attr_accessor :add_security_recommendation

        # @!attribute [rw] example_values
        #   The raw example input, kept so the placeholder/example counts can be
        #   compared without re-parsing the serialized payload.
        #   @return [Array, Hash, String, nil]
        attr_accessor :example_values

        validate :validate_shape
        validate :validate_text
        validate :validate_example

        # @param text [String, nil] The body text (max 1024 characters).
        # @param example [Array, Hash, String, nil] Sample values for the placeholders,
        #   or a pre-built example payload.
        # @param add_security_recommendation [Boolean, nil] Authentication templates
        #   only; mutually exclusive with `text`.
        # @param kwargs [Hash] Forwarded to {Base} (`parameter_format`).
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(text: nil, example: nil, add_security_recommendation: nil, **)
          super(**)

          @text = text
          @add_security_recommendation = add_security_recommendation
          @example_values = example
          @example = build_example_payload(role: :body, values: example)

          validate!
        end

        # @return [Boolean] Whether this is the flag-based authentication shape.
        def authentication?
          !add_security_recommendation.nil?
        end

        # @return [Hash] The serialized component.
        def serialize
          return { type: Defaults::TYPE, add_security_recommendation: } if authentication?

          {
            type: Defaults::TYPE,
            text:,
            example:,
          }.compact
        end

      private

        # @return [void]
        def validate_shape
          return unless authentication? && !blank_value?(text)

          errors.add(:text, "cannot be combined with add_security_recommendation")
        end

        # @return [void]
        def validate_text
          return if authentication?
          return errors.add(:text, "can't be blank") if blank_value?(text)

          if text.length > Defaults::MAX_TEXT_LENGTH
            errors.add(:text, "is too long (maximum is #{Defaults::MAX_TEXT_LENGTH} characters)")
          end

          validate_placeholder_style(text)
        end

        # The number of examples must match the number of placeholders exactly — a
        # mismatch is one of the most common causes of a rejected template.
        # @return [void]
        def validate_example
          # A shape mismatch is already reported by validate_example_shape, and
          # Example.count would raise on the same input.
          return if authentication? || blank_value?(text) || !example_error.nil?

          expected = Placeholders.count(text)
          return if expected.zero? && blank_value?(example)

          if blank_value?(example)
            return errors.add(:example,
              "can't be blank when the body text contains placeholders")
          end

          actual = Example.count(role: :body, parameter_format:, values: example_values)
          return if actual == expected

          errors.add(:example, count_mismatch_message(expected, actual))
        end

        # @return [String]
        def count_mismatch_message(expected, actual)
          "does not match the body text: #{expected} #{pluralize(expected, 'placeholder')} " \
            "but #{actual} #{pluralize(actual, 'example')}"
        end

        # @return [String]
        def pluralize(count, word)
          count == 1 ? word : "#{word}s"
        end
      end
    end
  end
end

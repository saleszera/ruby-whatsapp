# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Component
      # Shared behaviour for every component a template can declare.
      #
      # Holds the template's `parameter_format`, which every component accepts even
      # though only {Header} and {Body} use it. Uniformity is deliberate: {Component
      # .build} can then thread the format down without knowing which components care,
      # and carousel cards can pass it on to their own nested components.
      #
      # Each subclass owns its wire type as `Defaults::TYPE`, so the {Component::TYPES}
      # registry maps kind to class only and there is one source of truth.
      class Base
        include ValueObject

        # @!attribute [rw] parameter_format
        #   @return [String] see {ParameterFormats}.
        attr_accessor :parameter_format

        # @!attribute [r] example_error
        #   Set when the caller's example values could not be interpreted. See
        #   {#build_example_payload}.
        #   @return [String, nil]
        attr_reader :example_error

        validate :validate_example_shape

        # @param parameter_format [String, Symbol] The owning template's placeholder
        #   style. Defaults to Meta's own default.
        def initialize(parameter_format: ParameterFormats::POSITIONAL)
          @parameter_format = ParameterFormats.normalize(parameter_format)
        end

        # The uppercase value Meta expects in the component's `type` field.
        # @return [String]
        def api_type
          self.class::Defaults::TYPE
        end

      protected

        # Builds an example payload, deferring any shape mismatch to validation.
        #
        # {Example.serialize} raises ArgumentError when the values contradict the
        # parameter format (a Hash of names under POSITIONAL, say). Letting that escape
        # `initialize` would bypass the validation layer every other failure goes
        # through, leaving callers to handle two error types for one kind of mistake.
        # It is captured here and re-reported by {#validate_example_shape}.
        # @param role [Symbol] `:header` or `:body`.
        # @param values [Array, Hash, String, nil]
        # @return [Hash, nil]
        def build_example_payload(role:, values:)
          Example.serialize(role:, parameter_format:, values:)
        rescue ArgumentError => e
          @example_error = e.message
          nil
        end

        # Validates that text placeholders are well-formed and consistent with the
        # template's parameter format.
        #
        # Shared by {Header} and {Body} — the two components that accept placeholders —
        # because the three failure modes (mixed styles, a positional run that does not
        # start at 1, and a style that contradicts the template) are identical for both
        # and are among the most common causes of a rejected template.
        # @param text [String, nil]
        # @return [void]
        def validate_placeholder_style(text)
          return if blank_value?(text)

          style = Placeholders.style(text)
          return if style.nil?

          return errors.add(:text, "cannot mix positional and named placeholders") if style == :mixed
          return validate_named_style if style == :named

          validate_positional_style(text)
        end

      private

        # @return [void]
        def validate_example_shape
          errors.add(:example, example_error) unless example_error.nil?
        end

        # @return [void]
        def validate_named_style
          return if ParameterFormats.named?(parameter_format)

          errors.add(:text,
            "uses named placeholders but the template parameter_format is " \
              "#{ParameterFormats::POSITIONAL}")
        end

        # @return [void]
        def validate_positional_style(text)
          if ParameterFormats.named?(parameter_format)
            return errors.add(:text,
              "uses positional placeholders but the template parameter_format is #{ParameterFormats::NAMED}")
          end

          return if Placeholders.sequential?(text)

          errors.add(:text, "positional placeholders must start at {{1}} and increment without gaps")
        end
      end
    end
  end
end

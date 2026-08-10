# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # The two placeholder styles a template can declare, set once per template via
    # `parameter_format` and inherited by every component in it.
    #
    # POSITIONAL uses `{{1}}`, `{{2}}` — index numbers starting at 1, and send-side
    # values must be supplied in the same order. NAMED uses `{{first_name}}` —
    # lowercase-and-underscore names, and send-side values may be supplied in any
    # order. POSITIONAL is Meta's default when the field is omitted.
    #
    # The format also decides the *key name* of a component's `example` payload,
    # which is why it has to be threaded down into each component. See {Example}.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/overview
    module ParameterFormats
      POSITIONAL = "POSITIONAL"
      NAMED = "NAMED"

      ALL = [POSITIONAL, NAMED].freeze

      # Normalizes caller input to a canonical uppercase format string.
      #
      # Meta's own docs are inconsistent about enum casing, so callers may
      # reasonably pass `:named`, `"named"`, or `"NAMED"`. Unrecognized values are
      # returned untouched so validations can report them.
      # @param value [String, Symbol, nil]
      # @return [String, nil]
      def self.normalize(value)
        return if value.nil?

        candidate = value.to_s.upcase
        ALL.include?(candidate) ? candidate : value.to_s
      end

      # @param value [String, Symbol, nil]
      # @return [Boolean]
      def self.named?(value)
        normalize(value) == NAMED
      end

      # @param value [String, Symbol, nil]
      # @return [Boolean]
      def self.valid?(value)
        ALL.include?(normalize(value))
      end
    end
  end
end

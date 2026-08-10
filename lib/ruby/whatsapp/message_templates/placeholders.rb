# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # Parses the `{{...}}` placeholders out of template text.
    #
    # Three components need this (header text, body text, and the single variable a
    # URL button may append), so the pattern and the "what style is this?" question
    # live in one place rather than being re-derived per component.
    #
    # Placeholder names are collapsed to unique values in order of first appearance:
    # Meta counts a repeated `{{1}}` or `{{name}}` as one parameter, so the count a
    # caller must supply examples for is the unique count — that is {.count}. Where a
    # rule is about *position* rather than parameters, {.occurrences} counts repeats
    # instead; see the URL button.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/overview
    module Placeholders
      # Matches `{{name}}` / `{{1}}`, tolerating internal whitespace. Deliberately
      # restricted to word characters so malformed forms (`{{}}`, `{{a-b}}`) are not
      # mistaken for parameters.
      PATTERN = /\{\{\s*(\w+)\s*\}\}/

      # @param text [String, nil]
      # @return [Array<String>] Unique placeholder names, in order of appearance.
      def self.extract(text)
        text.to_s.scan(PATTERN).flatten.uniq
      end

      # @param text [String, nil]
      # @return [Integer] The number of unique placeholders.
      def self.count(text)
        extract(text).size
      end

      # @param text [String, nil]
      # @return [Integer] The number of placeholder occurrences, counting repeats.
      #   Contrast {.count}, which collapses repeated names. The URL button rule is
      #   positional — a single variable, appended at the very end — so a second
      #   occurrence breaks it even when it names the same parameter.
      def self.occurrences(text)
        text.to_s.scan(PATTERN).size
      end

      # @param text [String, nil]
      # @return [Symbol, nil] `:positional`, `:named`, `:mixed`, or nil when the text
      #   has no placeholders.
      def self.style(text)
        names = extract(text)
        return if names.empty?

        numeric, rest = names.partition { |name| name.match?(/\A\d+\z/) }

        return :positional if rest.empty?
        return :named if numeric.empty?

        :mixed
      end

      # @param text [String, nil]
      # @return [Boolean] true when the text has placeholders and all are numeric.
      def self.positional?(text)
        style(text) == :positional
      end

      # @param text [String, nil]
      # @return [Boolean] true when the text has placeholders and none are numeric.
      def self.named?(text)
        style(text) == :named
      end

      # Whether positional placeholders form the run 1..n that Meta requires.
      #
      # Order of appearance in the text does not matter — `"{{2}} after {{1}}"` is
      # valid — only that the set of indexes has no gaps and starts at 1. Text with
      # no placeholders, or named placeholders, is trivially sequential.
      # @param text [String, nil]
      # @return [Boolean]
      def self.sequential?(text)
        indexes = extract(text).grep(/\A\d+\z/).map(&:to_i)
        return true if indexes.empty?

        indexes.sort == (1..indexes.size).to_a
      end
    end
  end
end

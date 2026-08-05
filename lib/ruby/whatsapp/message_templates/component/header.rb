# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Component
      # The optional component above the body: a line of text, a media attachment, or
      # a location pin. At most one per template.
      #
      # Three shapes share one class because they all serialize to the same
      # `{type:, format:, ...}` envelope and differ only in which fields are legal.
      # The `format` decides:
      #
      #   TEXT     — `text` (60 chars, at most ONE placeholder) plus an `example`
      #   media    — `header_handle` from the Resumable Upload API; no text
      #   LOCATION — nothing else; coordinates are supplied when the message is sent
      #
      # This mirrors the conditional-validation approach already used by
      # {Whatsapp::Messages::Video} for its id-or-link choice.
      # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
      class Header < Base
        module Defaults
          TYPE = "HEADER"
          MAX_TEXT_LENGTH = 60
          MAX_VARIABLES = 1
        end

        module Formats
          TEXT = "TEXT"
          IMAGE = "IMAGE"
          VIDEO = "VIDEO"
          DOCUMENT = "DOCUMENT"
          GIF = "GIF"
          LOCATION = "LOCATION"

          # Formats that carry an uploaded asset handle rather than text.
          MEDIA = [IMAGE, VIDEO, DOCUMENT, GIF].freeze
          ALL = [TEXT, *MEDIA, LOCATION].freeze
        end

        # Characters Meta rejects in a header, which does not support Markdown.
        MARKDOWN_CHARACTERS = ["*", "_", "~", "`"].freeze

        # @!attribute [rw] format
        #   @return [String] one of {Formats::ALL}.
        attr_accessor :format

        # @!attribute [rw] text
        #   @return [String, nil] TEXT headers only.
        attr_accessor :text

        # @!attribute [rw] example
        #   @return [Hash, nil] The serialized example payload.
        attr_accessor :example

        # @!attribute [rw] header_handle
        #   @return [String, Array<String>, nil] Media headers only.
        attr_accessor :header_handle

        validates :format, presence: true, inclusion: { in: Formats::ALL }
        validate :validate_text_shape
        validate :validate_media_shape
        validate :validate_location_shape

        # @param format [String, Symbol] one of {Formats::ALL}, any casing.
        # @param text [String, nil] The header text, for the TEXT format.
        # @param example [Array, Hash, String, nil] A sample value for the text
        #   placeholder, or a pre-built example payload.
        # @param header_handle [String, Array<String>, nil] The uploaded asset handle,
        #   for media formats. A convenience alternative to
        #   `example: { header_handle: [...] }`.
        # @param kwargs [Hash] Forwarded to {Base} (`parameter_format`).
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(format:, text: nil, example: nil, header_handle: nil, **)
          super(**)

          @format = normalize_format(format)
          @text = text
          @header_handle = header_handle
          @example = build_example(example)

          validate!
        end

        # @return [Boolean] Whether this header carries an uploaded asset.
        def media?
          Formats::MEDIA.include?(format)
        end

        # @return [Hash] The serialized component.
        def serialize
          {
            type: Defaults::TYPE,
            format:,
            text:,
            example:,
          }.compact
        end

      private

        # Meta's docs are inconsistent about enum casing; accept either and emit
        # uppercase, which is what responses come back as.
        # @return [String, nil]
        def normalize_format(value)
          return if value.nil?

          candidate = value.to_s.upcase
          Formats::ALL.include?(candidate) ? candidate : value.to_s
        end

        # Builds the example payload from whichever input the caller used.
        # @return [Hash, nil]
        def build_example(value)
          return { header_handle: Array(header_handle) } unless blank_value?(header_handle)

          build_example_payload(role: :header, values: value)
        end

        # @return [void]
        def validate_text_shape
          return unless format == Formats::TEXT

          reject_unsupported(:header_handle, "cannot be set on a #{Formats::TEXT} header")
          validate_text_presence_and_length
          validate_text_variables
          validate_placeholder_style(text)
          validate_no_markdown
        end

        # @return [void]
        def validate_text_presence_and_length
          return errors.add(:text, "can't be blank") if blank_value?(text)
          return if text.length <= Defaults::MAX_TEXT_LENGTH

          errors.add(:text, "is too long (maximum is #{Defaults::MAX_TEXT_LENGTH} characters)")
        end

        # A text header supports at most one placeholder, and needs an example for it.
        # @return [void]
        def validate_text_variables
          count = Placeholders.count(text)
          return if count.zero?

          if count > Defaults::MAX_VARIABLES
            errors.add(:text, "supports at most one variable, found #{count}")
            return
          end

          errors.add(:example, "can't be blank when the header text contains a variable") if blank_value?(example)
        end

        # Checks only the literal text, with placeholders removed first.
        #
        # Named placeholders are lowercase-and-underscores by definition, so scanning
        # the raw text would reject `{{sale_start_date}}` for containing an underscore
        # and make named parameters unusable in a text header.
        # @return [void]
        def validate_no_markdown
          return if blank_value?(text)

          literal = text.gsub(Placeholders::PATTERN, "")
          found = MARKDOWN_CHARACTERS.select { |char| literal.include?(char) }
          return if found.empty?

          errors.add(:text, "cannot contain Markdown characters (found #{found.join(' ')})")
        end

        # @return [void]
        def validate_media_shape
          return unless media?

          reject_unsupported(:text, "cannot be set on a #{format} header")
          return unless blank_value?(example)

          errors.add(:header_handle, "can't be blank for a #{format} header")
        end

        # @return [void]
        def validate_location_shape
          return unless format == Formats::LOCATION

          reject_unsupported(:text, "cannot be set on a #{Formats::LOCATION} header")
          reject_unsupported(:header_handle, "cannot be set on a #{Formats::LOCATION} header")
        end
      end
    end
  end
end

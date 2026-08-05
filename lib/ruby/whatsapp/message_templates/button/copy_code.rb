# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Button
      # Copies a string — typically a coupon code — to the recipient's clipboard.
      #
      # Two things are unusual about this button: it carries no `text`, because Meta
      # supplies and localises the label itself; and its `example` is a bare string
      # rather than an array. At most one per template.
      #
      # In a limited-time-offer template the example is capped at 15 characters rather
      # than 20, and the button must sit at index 0 — both enforced by {Template},
      # which is the only place that can see the sibling components.
      # Source: https://developers.facebook.com/docs/whatsapp/business-management-api/message-templates/components/
      class CopyCode < Base
        module Defaults
          TYPE = "COPY_CODE"
          MAX_EXAMPLE_LENGTH = 20
        end

        # @!attribute [rw] example
        #   @return [String]
        attr_accessor :example

        # @!attribute [rw] text
        #   Always nil. Accepted only so a caller who supplies one gets told why it is
        #   not allowed, rather than an opaque ArgumentError.
        #   @return [nil]
        attr_accessor :text

        validates :example, presence: true, length: { maximum: Defaults::MAX_EXAMPLE_LENGTH }
        validate :validate_no_text

        # @param example [String] The code to copy (max 20 characters).
        # @param text [String, nil] Not supported — Meta supplies the label.
        #  @raise [ActiveModel::ValidationError] if validation fails.
        def initialize(example:, text: nil)
          @example = example
          @text = text

          validate!
        end

        # @return [Hash] The serialized button.
        def serialize
          { type: Defaults::TYPE, example: }
        end

      private

        # @return [void]
        def validate_no_text
          reject_unsupported(:text, "cannot be set on a copy-code button; Meta supplies the label")
        end
      end
    end
  end
end

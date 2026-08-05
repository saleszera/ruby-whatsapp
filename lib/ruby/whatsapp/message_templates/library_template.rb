# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # The payload for cloning one of Meta's pre-written library templates.
    #
    # A separate class from {Template} rather than another mode on it, because this
    # payload carries **no components at all** — the library template already defines
    # them, and only the parts Meta cannot know (a URL, a phone number, whether to
    # append an optional line) are supplied as inputs. Folding that into {Template}
    # would mean defeating its central "exactly one BODY" invariant.
    #
    # The payoff is instant approval: library templates are already categorised and
    # reviewed, so the create response usually comes back APPROVED rather than PENDING.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/template-library
    class LibraryTemplate
      include ValueObject

      # @!attribute [rw] name
      #   @return [String] The name to give *your* copy of the template.
      attr_accessor :name

      # @!attribute [rw] language
      #   @return [String]
      attr_accessor :language

      # @!attribute [rw] category
      #   @return [String]
      attr_accessor :category

      # @!attribute [rw] library_template_name
      #   @return [String] The library template being cloned.
      attr_accessor :library_template_name

      # @!attribute [rw] library_template_body_inputs
      #   @return [LibraryTemplate::BodyInputs, nil]
      attr_accessor :library_template_body_inputs

      # @!attribute [rw] library_template_button_inputs
      #   @return [Array<LibraryTemplate::ButtonInputs>, nil]
      attr_accessor :library_template_button_inputs

      validates :name, presence: true,
        format: { with: Template::Defaults::NAME_PATTERN,
                  message: "must contain only lowercase alphanumeric characters and underscores", },
        length: { maximum: Template::Defaults::MAX_NAME_LENGTH }
      validates :language, presence: true
      validates :category, presence: true, inclusion: { in: Categories::ALL }
      validates :library_template_name, presence: true
      validate :validate_language_code

      # @param name [String] The name for your copy; same rules as {Template}.
      # @param language [String] A locale code.
      # @param category [String, Symbol] One of {Categories::ALL}.
      # @param library_template_name [String] The library template to clone.
      # @param library_template_body_inputs [Hash, BodyInputs, nil] Optional body toggles.
      # @param library_template_button_inputs [Array<Hash, ButtonInputs>, nil] Optional
      #   per-button values.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(name:, language:, category:, library_template_name:,
        library_template_body_inputs: nil, library_template_button_inputs: nil)
        @name = name
        @language = language
        @category = Categories.normalize(category)
        @library_template_name = library_template_name
        @library_template_body_inputs = build_body_inputs(library_template_body_inputs)
        @library_template_button_inputs = build_button_inputs(library_template_button_inputs)

        validate!
      end

      # @return [Hash] The create-from-library payload.
      #
      # Note: Meta's docs show `library_template_button_inputs` as a JSON-*stringified*
      # array while the Graph API reference types it `array<JSON object>`. A real array
      # is emitted here, which matches the reference and how every other field on this
      # edge behaves. If the API rejects it, this method is the single place to change.
      def serialize
        {
          name:,
          language:,
          category:,
          library_template_name:,
          library_template_body_inputs: library_template_body_inputs&.serialize,
          library_template_button_inputs: library_template_button_inputs&.map(&:serialize),
        }.compact
      end

    private

      # @return [BodyInputs, nil]
      def build_body_inputs(inputs)
        return if blank_value?(inputs)
        return inputs if inputs.is_a?(BodyInputs)

        BodyInputs.new(**inputs)
      end

      # @return [Array<ButtonInputs>, nil]
      def build_button_inputs(inputs)
        return if blank_value?(inputs)

        Array(inputs).map { |input| input.is_a?(ButtonInputs) ? input : ButtonInputs.new(**input) }
      end

      # @return [void]
      def validate_language_code
        return if blank_value?(language) || Utils::LanguageCodes.valid?(language)

        errors.add(:language, "#{language.inspect} is not a valid WhatsApp language code")
      end
    end
  end
end

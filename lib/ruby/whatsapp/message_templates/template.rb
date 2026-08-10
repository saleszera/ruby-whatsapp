# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # The payload for creating a template, and for the multi-language upsert form.
    #
    # Owns the template's *identity* — name, language, category and the flags that
    # apply to the whole template. Everything about the components, including the rules
    # that span several of them, is delegated to {ComponentSet}; this class only passes
    # the category and parameter format down so those rules can be applied.
    #
    # Supports two language forms, which is why they are validated as an exclusive
    # choice: a single `language` for {MessageTemplates#create}, or a `languages` array
    # for {MessageTemplates#upsert}, which creates or updates the same template across
    # several locales in one call.
    #
    # Cloning a pre-written template from Meta's library is a different payload with no
    # components at all — see {LibraryTemplate}.
    # Source: https://developers.facebook.com/docs/graph-api/reference/whats-app-business-account/message_templates/
    class Template
      include ValueObject

      module Defaults
        # Meta accepts lowercase alphanumerics and underscores, nothing else.
        NAME_PATTERN = /\A[a-z0-9_]+\z/
        MAX_NAME_LENGTH = 512
      end

      # Refinements Meta recognises for order-related utility templates.
      module SubCategories
        ORDER_DETAILS = "ORDER_DETAILS"
        ORDER_STATUS = "ORDER_STATUS"
        RICH_ORDER_STATUS = "RICH_ORDER_STATUS"

        ALL = [ORDER_DETAILS, ORDER_STATUS, RICH_ORDER_STATUS].freeze
      end

      # @!attribute [rw] name
      #   @return [String]
      attr_accessor :name

      # @!attribute [rw] language
      #   @return [String, nil] A single locale code, for create.
      attr_accessor :language

      # @!attribute [rw] languages
      #   @return [Array<String>, nil] Several locale codes, for upsert.
      attr_accessor :languages

      # @!attribute [rw] category
      #   @return [String]
      attr_accessor :category

      # @!attribute [rw] parameter_format
      #   @return [String]
      attr_accessor :parameter_format

      # @!attribute [rw] component_set
      #   @return [ComponentSet]
      attr_accessor :component_set

      # @!attribute [rw] sub_category
      #   @return [String, nil]
      attr_accessor :sub_category

      # @!attribute [rw] message_send_ttl_seconds
      #   @return [Integer, nil]
      attr_accessor :message_send_ttl_seconds

      # @!attribute [rw] allow_category_change
      #   Effectively a no-op since 2025-04-09, when Meta made automatic
      #   recategorisation the default regardless of this flag. Kept because it is
      #   still a documented parameter.
      #   @return [Boolean, nil]
      attr_accessor :allow_category_change

      # @!attribute [rw] cta_url_link_tracking_opted_out
      #   @return [Boolean, nil]
      attr_accessor :cta_url_link_tracking_opted_out

      validates :name, presence: true,
        format: { with: Defaults::NAME_PATTERN,
                  message: "must contain only lowercase alphanumeric characters and underscores", },
        length: { maximum: Defaults::MAX_NAME_LENGTH }
      validates :category, presence: true, inclusion: { in: Categories::ALL }
      validates :parameter_format, inclusion: { in: ParameterFormats::ALL }
      validates :sub_category, inclusion: { in: SubCategories::ALL }, allow_nil: true
      validate :validate_language_choice
      validate :validate_language_codes
      validate :validate_message_send_ttl

      # @param name [String] The template name; lowercase alphanumerics and underscores.
      # @param category [String, Symbol] One of {Categories::ALL}.
      # @param components [Array<Hash, Component::Base>] The template's components.
      # @param language [String, nil] A single locale code. Mutually exclusive with
      #   `languages`.
      # @param languages [Array<String>, nil] Locale codes, for the upsert form.
      # @param parameter_format [String, Symbol] `POSITIONAL` (default) or `NAMED`.
      # @param sub_category [String, nil] One of {SubCategories::ALL}.
      # @param message_send_ttl_seconds [Integer, nil] Delivery-retry TTL override.
      # @param allow_category_change [Boolean, nil] See the attribute note.
      # @param cta_url_link_tracking_opted_out [Boolean, nil] Opt out of link tracking.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      #  @raise [TemplateError] if a component or button type is unknown.
      def initialize(name:, category:, components:, language: nil, languages: nil,
        parameter_format: ParameterFormats::POSITIONAL, sub_category: nil,
        message_send_ttl_seconds: nil, allow_category_change: nil,
        cta_url_link_tracking_opted_out: nil)
        @name = name
        @language = language
        @languages = languages
        @category = Categories.normalize(category)
        @parameter_format = ParameterFormats.normalize(parameter_format)
        @sub_category = sub_category
        @message_send_ttl_seconds = message_send_ttl_seconds
        @allow_category_change = allow_category_change
        @cta_url_link_tracking_opted_out = cta_url_link_tracking_opted_out
        @component_set = ComponentSet.new(components:, category: @category, parameter_format: @parameter_format)

        validate!
      end

      # @return [Array<Component::Base>]
      def components
        component_set.components
      end

      # @return [Hash] The create/upsert payload.
      def serialize
        {
          name:,
          **language_payload,
          category:,
          parameter_format:,
          components: component_set.serialize,
          sub_category:,
          message_send_ttl_seconds:,
          allow_category_change:,
          cta_url_link_tracking_opted_out:,
        }.compact
      end

    private

      # @return [Hash] Either `language` or `languages`, never both.
      def language_payload
        return { languages: } unless blank_value?(languages)

        { language: }
      end

      # @return [void]
      def validate_language_choice
        single = !blank_value?(language)
        multiple = !blank_value?(languages)

        return errors.add(:base, "language and languages cannot be combined") if single && multiple
        return if single || multiple

        errors.add(:base, "requires either language or languages")
      end

      # @return [void]
      def validate_language_codes
        codes = blank_value?(languages) ? [language] : Array(languages)

        codes.compact.reject { |code| Utils::LanguageCodes.valid?(code) }.each do |code|
          errors.add(:language, "#{code.inspect} is not a valid WhatsApp language code")
        end
      end

      # @return [void]
      def validate_message_send_ttl
        return if message_send_ttl_seconds.nil? || message_send_ttl_seconds.is_a?(Integer)

        errors.add(:message_send_ttl_seconds, "must be an integer number of seconds")
      end
    end
  end
end

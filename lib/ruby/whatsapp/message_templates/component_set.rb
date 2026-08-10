# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # A template's components, plus every rule that spans more than one of them.
    #
    # This is the other half of the split described in {Component}: a component class
    # validates itself, and everything about how components *relate* lives here. That
    # keeps rules like "a footer is forbidden alongside a limited-time offer" in one
    # place instead of duplicated across the sibling classes that would each only see
    # half the picture.
    #
    # It is a separate object from {Template} because editing a template replaces its
    # components wholesale without re-supplying a name or language, so `update` needs
    # exactly these checks and none of the template-identity ones.
    #
    # `category` is optional for that reason: when it is absent — as when editing — the
    # category-dependent rules are skipped rather than guessed at.
    class ComponentSet
      include ValueObject

      module Defaults
        # A limited-time-offer template caps the body well below the usual 1024.
        LIMITED_TIME_OFFER_MAX_BODY_LENGTH = 600
        # ...and its copy-code button below the usual 20.
        LIMITED_TIME_OFFER_MAX_COPY_CODE_LENGTH = 15
      end

      # Wire types that may appear at most once in a template.
      SINGLETON_TYPES = [
        Component::Header::Defaults::TYPE,
        Component::Footer::Defaults::TYPE,
        Component::Buttons::Defaults::TYPE,
        Component::Carousel::Defaults::TYPE,
        Component::LimitedTimeOffer::Defaults::TYPE,
      ].freeze

      # Components restricted to a subset of categories, and which ones.
      CATEGORY_RESTRICTED_TYPES = {
        Component::Carousel::Defaults::TYPE => [Categories::MARKETING].freeze,
        Component::LimitedTimeOffer::Defaults::TYPE => [Categories::MARKETING].freeze,
      }.freeze

      # Header formats a limited-time-offer template may use.
      LIMITED_TIME_OFFER_HEADER_FORMATS = [
        Component::Header::Formats::IMAGE,
        Component::Header::Formats::VIDEO,
      ].freeze

      # Categories that may use a location header.
      LOCATION_HEADER_CATEGORIES = [Categories::UTILITY, Categories::MARKETING].freeze

      # @!attribute [rw] components
      #   @return [Array<Component::Base>]
      attr_accessor :components

      # @!attribute [rw] category
      #   @return [String, nil]
      attr_accessor :category

      # @!attribute [rw] parameter_format
      #   @return [String]
      attr_accessor :parameter_format

      validates :components, presence: true
      validate :validate_body_count
      validate :validate_singletons
      validate :validate_category_restrictions
      validate :validate_location_header
      validate :validate_limited_time_offer

      # @param components [Array<Hash, Component::Base>] The template's components.
      # @param category [String, Symbol, nil] The owning template's category. Omit to
      #   skip the category-dependent rules.
      # @param parameter_format [String, Symbol] The placeholder style, threaded into
      #   every component.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      #  @raise [TemplateError] if a component type is unknown.
      def initialize(components:, category: nil, parameter_format: ParameterFormats::POSITIONAL)
        @category = Categories.normalize(category)
        @parameter_format = ParameterFormats.normalize(parameter_format)
        @components = build_components(components)

        validate!
      end

      # @param api_type [String] A component wire type, e.g. `"BODY"`.
      # @return [Component::Base, nil]
      def find(api_type)
        components.find { |component| component.api_type == api_type }
      end

      # @return [Array<String>] The wire types present, in declared order.
      def api_types
        components.map(&:api_type)
      end

      # @return [Array<Hash>] The serialized components.
      def serialize
        components.map(&:serialize)
      end

    private

      # @return [Array<Component::Base>]
      def build_components(list)
        Array(list).map do |component|
          next component if component.is_a?(Component::Base)

          Component.build(**component, parameter_format:)
        end
      end

      # @return [void]
      def validate_body_count
        return if api_types.count(Component::Body::Defaults::TYPE) == 1

        errors.add(:components, "requires exactly one BODY component")
      end

      # @return [void]
      def validate_singletons
        SINGLETON_TYPES.each do |type|
          next if api_types.count(type) <= 1

          errors.add(:components, "allow at most one #{type} component")
        end
      end

      # @return [void]
      def validate_category_restrictions
        return if category.nil?

        CATEGORY_RESTRICTED_TYPES.each do |type, allowed|
          next unless api_types.include?(type)
          next if allowed.include?(category)

          errors.add(:components, "#{type} is only supported on #{allowed.join('/')} templates, not #{category}")
        end
      end

      # @return [void]
      def validate_location_header
        return if category.nil?

        header = find(Component::Header::Defaults::TYPE)
        return unless header&.format == Component::Header::Formats::LOCATION
        return if LOCATION_HEADER_CATEGORIES.include?(category)

        errors.add(:components,
          "a LOCATION header is only supported on #{LOCATION_HEADER_CATEGORIES.join('/')} templates, not #{category}")
      end

      # A limited-time offer reshapes the rest of the template: no footer, a shorter
      # body, a media-only header, and a copy-code button that must come first.
      # @return [void]
      def validate_limited_time_offer
        return unless api_types.include?(Component::LimitedTimeOffer::Defaults::TYPE)

        validate_offer_has_no_footer
        validate_offer_body_length
        validate_offer_header_format
        validate_offer_buttons
      end

      # @return [void]
      def validate_offer_has_no_footer
        return unless api_types.include?(Component::Footer::Defaults::TYPE)

        errors.add(:components, "a FOOTER is not allowed in a LIMITED_TIME_OFFER template")
      end

      # @return [void]
      def validate_offer_body_length
        text = find(Component::Body::Defaults::TYPE)&.text
        return if text.nil? || text.length <= Defaults::LIMITED_TIME_OFFER_MAX_BODY_LENGTH

        errors.add(:components,
          "the BODY of a LIMITED_TIME_OFFER template is limited to " \
            "#{Defaults::LIMITED_TIME_OFFER_MAX_BODY_LENGTH} characters")
      end

      # @return [void]
      def validate_offer_header_format
        header = find(Component::Header::Defaults::TYPE)
        return if header.nil? || LIMITED_TIME_OFFER_HEADER_FORMATS.include?(header.format)

        errors.add(:components,
          "the header must be IMAGE or VIDEO in a LIMITED_TIME_OFFER template, got #{header.format}")
      end

      # @return [void]
      def validate_offer_buttons
        buttons = find(Component::Buttons::Defaults::TYPE)&.buttons
        return if buttons.nil?

        copy_code = buttons.find { |button| button.is_a?(Button::CopyCode) }
        return if copy_code.nil?

        validate_offer_copy_code_position(buttons, copy_code)
        validate_offer_copy_code_length(copy_code)
      end

      # @return [void]
      def validate_offer_copy_code_position(buttons, copy_code)
        return if buttons.index(copy_code).zero?

        errors.add(:components, "the copy-code button must be first in a LIMITED_TIME_OFFER template")
      end

      # @return [void]
      def validate_offer_copy_code_length(copy_code)
        maximum = Defaults::LIMITED_TIME_OFFER_MAX_COPY_CODE_LENGTH
        return if copy_code.example.to_s.length <= maximum

        errors.add(:components,
          "the copy-code example is limited to #{maximum} characters in a LIMITED_TIME_OFFER template")
      end
    end
  end
end

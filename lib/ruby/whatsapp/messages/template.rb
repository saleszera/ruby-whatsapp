# frozen_string_literal: true

module Whatsapp
  class Messages
    # Template messages allow you to send marketing, utility, and authentication templates to WhatsApp users.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/messages/template-messages
    class Template < Base
      module Defaults
        TYPE = "template"
      end

      # @!attribute [rw] name
      #   @return [String]
      attr_accessor :name

      # @!attribute [rw] language
      #   @return [Language]
      attr_accessor :language

      # @!attribute [rw] components
      #   @return [Array<Component>]
      attr_accessor :components

      validates :name, presence: true
      validates :language, presence: true

      # @param name [String] The template name.
      # @param language [Hash, Language] The language configuration with code.
      # @param components [Array<Hash, Component>] Array of component hashes (optional).
      # @param kwargs [Hash] Additional keyword arguments.
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(name:, language:, components: [], **)
        super(**)

        @name = name
        @language = language.is_a?(Language) ? language : Language.new(**language)
        @components = components.map { |comp| comp.is_a?(Component) ? comp : Component.new(**comp) }

        validate!
      end

      # Serializes the template message to a hash format suitable for the WhatsApp API.
      # @return [Hash] The serialized template message.
      def serialize
        envelope(type: Defaults::TYPE, template: template_payload)
      end

    private

      # @return [Hash] The serialized template payload.
      def template_payload
        {
          name:,
          language: language.serialize,
          components: components.map(&:serialize),
        }.tap do |payload|
          payload.delete(:components) if components.empty?
        end
      end
    end
  end
end

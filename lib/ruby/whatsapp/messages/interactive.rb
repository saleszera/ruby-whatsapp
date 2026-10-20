# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive < Base
      module Defaults
        TYPE = "interactive"
      end

      # Maps a public action kind to its implementing class and the WhatsApp
      # `interactive.type` value emitted in the payload. Resolution goes through
      # this frozen whitelist — never `const_get` on caller input.
      #
      # NOTE: the carousel `api_type` values ("carousel"/"product_list") should be
      # verified against the Meta docs for your API version before relying on them.
      ACTION_TYPES = {
        reply_buttons: { klass: ReplyButtons, api_type: "button" },
        list_buttons: { klass: ListButtons, api_type: "list" },
        url_button: { klass: UrlButton, api_type: "cta_url" },
        media_carousel: { klass: MediaCarousel, api_type: "carousel" },
        product_carousel: { klass: ProductCarousel, api_type: "product_list" },
        # The one kind whose registry key and wire value coincide — the registry exists
        # because they usually differ, so this is not a copy-paste slip. `parameterless`
        # marks the one kind with nothing for a caller to supply; see #validate_action.
        request_contact_info: { klass: RequestContactInfo, api_type: "request_contact_info", parameterless: true },
      }.freeze

      # @!attribute [rw] type
      #   @return [Symbol] The action kind (e.g. :reply_buttons, :list_buttons).
      attr_accessor :type

      # @!attribute [rw] header
      #   @return [Hash, nil]
      attr_accessor :header

      # @!attribute [rw] body
      #   @return [String]
      attr_accessor :body

      # @!attribute [rw] footer
      #   @return [Hash, nil]
      attr_accessor :footer

      # @!attribute [rw] action
      #   @return [Hash]
      attr_accessor :action

      validates :type, presence: true, inclusion: { in: ACTION_TYPES.keys }
      validates :body, presence: true
      validate :validate_action

      # @param type [Symbol, String] The action kind (see {ACTION_TYPES}).
      # @param body [String] The body text of the interactive message.
      # @param action [Hash] The action content, forwarded to the action class. Defaults to
      #   empty, which only the parameterless `:request_contact_info` kind accepts.
      # @param header [Hash, nil] The header content (optional).
      # @param footer [Hash, nil] The footer content (optional).
      # @param kwargs [Hash] Additional keyword arguments passed to {Base} (:to / :recipient).
      #  @raise [ActiveModel::ValidationError] if validation fails.
      def initialize(type:, body:, action: {}, header: nil, footer: nil, **)
        super(**)

        @type = type.to_sym
        @body = body
        @action = action
        @header = header
        @footer = footer

        validate!
      end

      # @return [Hash] Serialized representation of the Interactive message.
      def serialize
        envelope(type: Defaults::TYPE, interactive: interactive_payload)
      end

    private

      # @return [Hash] The serialized `interactive` payload.
      def interactive_payload
        {
          type: action_config[:api_type],
          header: serialized_header,
          body: serialized_body,
          footer: serialized_footer,
          action: action_config[:klass].serialize(**action),
        }.compact
      end

      # @return [Hash] The registry entry for the current action kind.
      def action_config
        ACTION_TYPES.fetch(type)
      end

      # An empty `action` is blank, so a plain presence validator would reject the one kind
      # that legitimately has nothing to supply. Reads the registry with `[]` rather than
      # the `fetch`-backed #action_config, so an unknown `type` falls through to the
      # inclusion validator above instead of raising KeyError from inside a validator.
      # @return [void]
      def validate_action
        config = ACTION_TYPES[type]
        return if config.nil? || config[:parameterless]
        return if action.present?

        errors.add(:action, "can't be blank")
      end

      # @return [Hash, nil] The serialized header information.
      def serialized_header
        return unless header

        Header.serialize(**header)
      end

      # @return [Hash, nil] The serialized footer information.
      def serialized_footer
        return unless footer

        Footer.serialize(**footer)
      end

      # @return [Hash, nil] The serialized body information.
      def serialized_body
        return unless body

        Body.serialize(body)
      end
    end
  end
end

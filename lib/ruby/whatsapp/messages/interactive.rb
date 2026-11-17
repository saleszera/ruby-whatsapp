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
      # Both carousels share the wire type "carousel" and are distinguished by their
      # cards. `body_only` marks the kinds Meta forbids a message-level header and
      # footer on; see #validate_body_only.
      ACTION_TYPES = {
        reply_buttons: { klass: ReplyButtons, api_type: "button" },
        list_buttons: { klass: ListButtons, api_type: "list" },
        url_button: { klass: UrlButton, api_type: "cta_url" },
        media_carousel: { klass: MediaCarousel, api_type: "carousel", body_only: true },
        product_carousel: { klass: ProductCarousel, api_type: "carousel", body_only: true },
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

      # What building a nested part from caller input can raise: its own validation
      # failure, an unknown or missing keyword (ArgumentError), a non-Hash where a Hash
      # is expected (TypeError), or an incomplete header. Each is reported as a
      # validation error on the part, so one kind of mistake has one exception type.
      PART_ERRORS = [ActiveModel::ValidationError, ArgumentError, TypeError, Header::HeaderError].freeze

      validates :type, presence: true, inclusion: { in: ACTION_TYPES.keys }
      validates :body, presence: true
      validate :validate_action
      validate :validate_body_only
      validate :validate_parts

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

        @type = type&.to_sym
        @body = body
        @action = action
        @header = header
        @footer = footer

        validate!
      end

      # Describes what building a nested part or card raised, for reporting it as a
      # validation error on the object that holds it. Shared with {CarouselCards}.
      # @param error [StandardError]
      # @return [String]
      def self.nested_error_message(error)
        return error.model.errors.full_messages.join(", ") if error.is_a?(ActiveModel::ValidationError)

        error.message
      end

      # @return [Hash] Serialized representation of the Interactive message.
      def serialize
        envelope(type: Defaults::TYPE, interactive: interactive_payload)
      end

    private

      # @return [Hash] The serialized `interactive` payload.
      def interactive_payload
        { type: action_config[:api_type], **part_builders.transform_values(&:call) }
      end

      # How to serialize each part that is present, in payload order. Shared by
      # {#interactive_payload} and {#validate_parts}, so validation exercises exactly
      # the code that serialization will run.
      # @return [Hash{Symbol => Proc}]
      def part_builders
        {
          header: header && -> { Header.serialize(**header) },
          body: body.present? && -> { Body.serialize(body) },
          footer: footer && -> { Footer.serialize(**footer) },
          action: action_buildable? && -> { action_config[:klass].serialize(**action) },
        }.select { |_part, builder| builder }
      end

      # Whether the action can be built at all; an unknown type or a missing action is
      # already reported by the inclusion validator and {#validate_action}.
      # @return [Boolean]
      def action_buildable?
        config = ACTION_TYPES[type]
        !config.nil? && (config[:parameterless] || action.present?)
      end

      # Builds every present part, recording whatever building one raises as an error on
      # that part, so `valid?` is true only when {#serialize} will succeed.
      # @return [void]
      def validate_parts
        part_builders.each do |part, builder|
          builder.call
        rescue *PART_ERRORS => e
          errors.add(part, :invalid, message: "is invalid: #{self.class.nested_error_message(e)}")
        end
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

      # Carousels carry their media on the cards, so Meta rejects a message-level
      # header or footer on them.
      # @return [void]
      def validate_body_only
        return unless ACTION_TYPES.dig(type, :body_only)

        { header:, footer: }.each do |part, value|
          errors.add(part, "is not supported on a #{type} message") unless value.nil?
        end
      end
    end
  end
end

# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module ConversationalAutomation
      # Configures a phone number's conversational components: the welcome-message switch, the
      # ice breakers (`prompts`), and the `/commands`.
      #
      # A validated instance rather than a bare class method (unlike {Get}, which has nothing
      # to check): Meta documents counts, lengths, unique command names and "no emoji", and
      # since every field is optional an all-nil call would spend a request to change nothing.
      #
      # Meta documents no `DELETE` for this edge. An omitted field is compacted away (left
      # alone), while `false` and an empty array are sent through — that is how the welcome
      # message is switched off and a list is cleared.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/conversational-automation-api
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/conversational-components
      class Update
        include ActiveModel::Validations
        extend ResponseHandling
        extend Transport

        module Defaults
          EDGE = "conversational_automation"
        end

        # What building a command from caller input can raise: the command's own validation,
        # a missing or unknown keyword, or an entry that is neither a Hash nor a {Command}.
        COMMAND_ERRORS = [ActiveModel::ValidationError, ArgumentError, TypeError].freeze

        # Every updatable field, in payload order. Drives both the "change something" guard
        # and its message, so the two cannot drift apart.
        ATTRIBUTES = %i[enable_welcome_message prompts commands].freeze

        # @!attribute [rw] enable_welcome_message
        #   @return [Boolean, nil] Whether WhatsApp sends a `request_welcome` webhook when a
        #     user opens a chat with no prior thread.
        attr_accessor :enable_welcome_message

        # @!attribute [rw] prompts
        #   @return [Array<String>, nil] At most {Limits::PROMPTS} ice breakers.
        attr_accessor :prompts

        # @!attribute [rw] commands
        #   @return [Array<Command, Hash>, nil] At most {Limits::COMMANDS} commands, as given.
        attr_accessor :commands

        validate :validate_any_attribute_present
        validate :validate_enable_welcome_message
        validate :validate_prompts
        validate :validate_commands

        # @example Configure everything at once
        #   Update.new(
        #     enable_welcome_message: true,
        #     prompts: ["Book a flight", "Plan a vacation"],
        #     commands: [{ command_name: "tickets", command_description: "Book flight tickets" }]
        #   )
        # @param enable_welcome_message [Boolean, nil] `true` or `false`; no truthy coercion.
        # @param prompts [Array<String>, nil] Ice breakers, each at most
        #   {Limits::PROMPT_LENGTH} characters with no emoji. `[]` clears them.
        # @param commands [Array<Command, Hash>, nil] {Command}s, or hashes with
        #   `command_name`/`command_description` keys (symbol or string, so the list
        #   {Details#commands} returns can be sent straight back). `[]` clears them.
        # @raise [ActiveModel::ValidationError] if every field is nil, or one breaks a
        #   documented rule.
        def initialize(enable_welcome_message: nil, prompts: nil, commands: nil)
          @enable_welcome_message = enable_welcome_message
          @prompts = prompts
          @commands = commands

          validate!
        end

        # @return [Hash] The update payload, with every omitted field compacted away rather
        #   than sent as null. `false` and empty arrays survive on purpose.
        def serialize
          {
            enable_welcome_message:,
            prompts:,
            commands: commands&.map { |command| coerce_command(command).serialize },
          }.compact
        end

        class << self
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @param enable_welcome_message [Boolean, nil] See {#initialize}.
          # @param prompts [Array<String>, nil] See {#initialize}.
          # @param commands [Array<Command, Hash>, nil] See {#initialize}.
          # @return [BusinessPhoneNumber::Response]
          # @raise [ActiveModel::ValidationError] if no field is given, or one is invalid.
          # @raise [Error] if no phone number ID is configured, or the request fails.
          def call(client: Client.new, enable_welcome_message: nil, prompts: nil, commands: nil)
            body = new(enable_welcome_message:, prompts:, commands:).serialize
            response = client.connection.post(edge_path(client, Defaults::EDGE), json: body)

            BusinessPhoneNumber::Response.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "update conversational automation"))
            )
          end
        end

      private

        # @return [void]
        def validate_any_attribute_present
          return if ATTRIBUTES.any? { |attribute| !public_send(attribute).nil? }

          errors.add(:base, "at least one of #{ATTRIBUTES.join(', ')} must be provided")
        end

        # @return [void]
        def validate_enable_welcome_message
          return if [nil, true, false].include?(enable_welcome_message)

          errors.add(:enable_welcome_message, :inclusion, message: "must be true or false")
        end

        # @return [void]
        def validate_prompts
          validate_list(:prompts, Limits::PROMPTS)
          return unless prompts.is_a?(Array)

          prompts.each_with_index { |prompt, index| validate_prompt(prompt, index) }
        end

        # @param prompt [Object]
        # @param index [Integer]
        # @return [void]
        def validate_prompt(prompt, index)
          problem =
            if !prompt.is_a?(String) then "must be a String"
            elsif prompt.strip.empty? then "can't be blank"
            elsif prompt.length > Limits::PROMPT_LENGTH
              "is too long (maximum is #{Limits::PROMPT_LENGTH} characters)"
            elsif Limits.emoji?(prompt) then "must not contain emoji"
            end
          return if problem.nil?

          errors.add(:prompts, :invalid, message: "entry at index #{index} #{problem}")
        end

        # Builds every command during validation, so a malformed one is reported on
        # `:commands` — with its index — instead of raising out of `valid?`. The uniqueness
        # rule runs only once every command has built.
        # @return [void]
        def validate_commands
          validate_list(:commands, Limits::COMMANDS)
          return unless commands.is_a?(Array)

          built = commands.each_with_index.map { |command, index| build_command(command, index) }
          return unless built.all?

          duplicates = built.map(&:command_name).tally.select { |_name, count| count > 1 }.keys
          return if duplicates.empty?

          errors.add(:commands, :taken,
            message: "must have unique command names (duplicated: #{duplicates.join(', ')})")
        end

        # @param command [Object]
        # @param index [Integer]
        # @return [Command, nil] The built command, or nil after reporting why it is invalid.
        def build_command(command, index)
          coerce_command(command)
        rescue *COMMAND_ERRORS => e
          errors.add(:commands, :invalid, message: "contain an invalid command at index #{index}: #{describe(e)}")
          nil
        end

        # @param command [Command, Hash]
        # @return [Command]
        # @raise [TypeError] if the entry is neither a {Command} nor a Hash.
        def coerce_command(command)
          return command if command.is_a?(Command)
          raise TypeError, "expected a Hash or a Command, got #{command.class}" unless command.is_a?(Hash)

          Command.new(**command.transform_keys(&:to_sym))
        end

        # The shared shape check for both lists: nil is "leave alone", anything else must be an
        # Array within the documented count. The caller checks the entries only for an Array.
        # @param attribute [Symbol]
        # @param maximum [Integer]
        # @return [void]
        def validate_list(attribute, maximum)
          value = public_send(attribute)
          return if value.nil?
          return errors.add(attribute, :invalid, message: "must be an Array") unless value.is_a?(Array)

          errors.add(attribute, :too_long, message: "accepts at most #{maximum} entries") if value.size > maximum
        end

        # @param error [StandardError]
        # @return [String]
        def describe(error)
          return error.model.errors.full_messages.join(", ") if error.is_a?(ActiveModel::ValidationError)

          error.message
        end
      end
    end
  end
end

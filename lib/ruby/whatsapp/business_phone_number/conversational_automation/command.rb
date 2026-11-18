# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module ConversationalAutomation
      # One `/command` a WhatsApp user sees after typing a slash in a chat with the business:
      # the command itself and a hint describing what it does.
      #
      # Write-side only. {Update} builds these from caller input; {Details} deliberately keeps
      # the commands Meta echoes back as raw hashes, so these validators never run over a
      # payload Meta has already accepted.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/conversational-components
      class Command
        include ActiveModel::Validations

        # @!attribute [rw] command_name
        #   @return [String] The command, without its leading slash, at most
        #     {Limits::COMMAND_NAME_LENGTH} characters.
        attr_accessor :command_name

        # @!attribute [rw] command_description
        #   @return [String] The hint shown next to the command, at most
        #     {Limits::COMMAND_DESCRIPTION_LENGTH} characters.
        attr_accessor :command_description

        validate :validate_command_name
        validate :validate_command_description

        # @example
        #   Command.new(command_name: "tickets", command_description: "Book flight tickets")
        # @param command_name [String] Without the leading `/` — WhatsApp adds it.
        # @param command_description [String]
        # @raise [ActiveModel::ValidationError] if either field is blank, too long, or contains
        #   an emoji, or if command_name starts with `/`.
        def initialize(command_name:, command_description:)
          @command_name = command_name
          @command_description = command_description

          validate!
        end

        # @return [Hash] The command as Meta expects it inside `commands`.
        def serialize
          { command_name:, command_description: }
        end

      private

        # @return [void]
        def validate_command_name
          validate_text(:command_name, Limits::COMMAND_NAME_LENGTH)
          return unless command_name.is_a?(String) && command_name.start_with?("/")

          errors.add(:command_name, :invalid, message: 'must not start with "/"; WhatsApp adds it')
        end

        # @return [void]
        def validate_command_description
          validate_text(:command_description, Limits::COMMAND_DESCRIPTION_LENGTH)
        end

        # The rules both fields share: a non-blank String, within its length, with no emoji.
        # @param attribute [Symbol]
        # @param maximum [Integer]
        # @return [void]
        def validate_text(attribute, maximum)
          value = public_send(attribute)
          return errors.add(attribute, :blank) if value.nil?
          return errors.add(attribute, :invalid, message: "must be a String") unless value.is_a?(String)
          return errors.add(attribute, :blank) if value.strip.empty?

          errors.add(attribute, :too_long, count: maximum) if value.length > maximum
          errors.add(attribute, :invalid, message: "must not contain emoji") if Limits.emoji?(value)
        end
      end
    end
  end
end

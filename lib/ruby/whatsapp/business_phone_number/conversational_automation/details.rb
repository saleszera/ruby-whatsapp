# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module ConversationalAutomation
      # The conversational components configured on a phone number, as returned by {Get}.
      #
      # Owns the `{"conversational_automation": {...}, "id": "..."}` envelope, the same habit
      # as {Profile::Details#unwrap}. Every field tolerates being absent. Nothing is validated
      # on the way in: `commands` stay the raw hashes Meta sent rather than {Command}s, so a
      # limit Meta relaxes later can never make a read fail — the same reasoning as
      # {Whatsapp::MessageTemplates::Response::Node}'s raw components. Those hashes can be
      # passed straight back to {Update}.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/conversational-components
      class Details
        # The response key wrapping the configuration.
        ENVELOPE = "conversational_automation"

        # @!attribute [rw] id
        #   @return [String, nil] The phone number ID.
        attr_accessor :id

        # @!attribute [rw] enable_welcome_message
        #   @return [Boolean, nil] As sent by Meta; current docs omit it from the sample
        #     response, so nil means "not reported". Use {#welcome_message_enabled?} to branch.
        attr_accessor :enable_welcome_message

        # @!attribute [rw] prompts
        #   @return [Array<String>] The ice breakers; empty when none are configured.
        attr_accessor :prompts

        # @!attribute [rw] commands
        #   @return [Array<Hash>] `{"command_name" => ..., "command_description" => ...}`
        #     hashes; empty when none are configured.
        attr_accessor :commands

        # @param id [String, nil]
        # @param enable_welcome_message [Boolean, nil]
        # @param prompts [Array<String>]
        # @param commands [Array<Hash>]
        def initialize(id: nil, enable_welcome_message: nil, prompts: [], commands: [])
          @id = id
          @enable_welcome_message = enable_welcome_message
          @prompts = prompts
          @commands = commands
        end

        # @return [Boolean] Whether Meta reported the welcome message as enabled. Strict:
        #   only a literal `true` counts.
        def welcome_message_enabled?
          enable_welcome_message == true
        end

        class << self
          # @param response [Hash, nil] The parsed response body, envelope included.
          # @return [Details]
          def deserialize(response)
            response ||= {}
            automation = response[ENVELOPE] || {}

            new(
              id: response["id"],
              enable_welcome_message: automation["enable_welcome_message"],
              prompts: Array(automation["prompts"]),
              commands: Array(automation["commands"])
            )
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module ConversationalAutomation
      # The content rules Meta documents for conversational components, shared by {Update}
      # (prompts and the command count) and {Command} (each command's fields). Its own file
      # because it has two consumers, like {Profile::Verticals}.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/conversational-components
      module Limits
        # Ice breakers per phone number.
        PROMPTS = 4
        # Characters per ice breaker.
        PROMPT_LENGTH = 80
        # Commands per phone number.
        COMMANDS = 30
        # Characters per command name (Meta's "command").
        COMMAND_NAME_LENGTH = 32
        # Characters per command description (Meta's "hint").
        COMMAND_DESCRIPTION_LENGTH = 256

        # Meta: "Emojis are not supported" in prompts or commands.
        #
        # Matches anything *rendered* as an emoji: a default-emoji code point, a pictograph
        # forced into emoji style by U+FE0F, a flag half, or a keycap. Deliberately not
        # `\p{Emoji}`/`\p{Extended_Pictographic}` alone — those also match text symbols such
        # as `©`, `™` and `#`, which would reject ordinary copy. A pictograph in its default
        # text presentation (a bare `✈`) gets through; Meta still has the final say.
        EMOJI_PATTERN = /
          \p{Emoji_Presentation}
          | \p{Extended_Pictographic}️
          | \p{Regional_Indicator}
          | ⃣
        /x

        # @param text [String]
        # @return [Boolean] Whether the text contains anything rendered as an emoji.
        def self.emoji?(text)
          text.match?(EMOJI_PATTERN)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # The three categories every template must declare.
    #
    # The choice is not cosmetic: it drives pricing, it decides which components are
    # legal, and Meta validates it against the template's actual content — a mismatch
    # comes back as REJECTED with the reason INCORRECT_CATEGORY.
    #
    # Shared by {Template}, {ComponentSet} and {LibraryTemplate}, hence its own file
    # rather than living on any one of them.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/templates/template-categorization
    module Categories
      # Identity verification with one-time passcodes. No URLs, media, or emojis, and
      # parameters are capped at 15 characters.
      AUTHENTICATION = "AUTHENTICATION"
      # Promotions, awareness, retargeting. Anything ambiguous lands here.
      MARKETING = "MARKETING"
      # Transactional and non-promotional: order, account, or transaction updates, or
      # genuinely essential notices.
      UTILITY = "UTILITY"

      ALL = [AUTHENTICATION, MARKETING, UTILITY].freeze

      # Normalizes caller input to a canonical uppercase category.
      #
      # Meta's own docs are inconsistent about enum casing, so callers may reasonably
      # pass `:marketing`, `"marketing"`, or `"MARKETING"`. Unrecognized values are
      # returned untouched so validations can report them.
      # @param value [String, Symbol, nil]
      # @return [String, nil]
      def self.normalize(value)
        return if value.nil?

        candidate = value.to_s.upcase
        ALL.include?(candidate) ? candidate : value.to_s
      end

      # @param value [String, Symbol, nil]
      # @return [Boolean]
      def self.valid?(value)
        ALL.include?(normalize(value))
      end
    end
  end
end

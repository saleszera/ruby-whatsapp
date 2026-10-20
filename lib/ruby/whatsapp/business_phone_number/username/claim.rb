# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Username
      # Claims a business username for a phone number, or moves one you already hold onto
      # a different number of yours.
      #
      # A validated instance rather than a bare class method: Meta publishes the username
      # format as a set of client-side rules, and the edge is rate limited, so a request
      # that was never going to be accepted should not be spent. Named {Claim} rather than
      # `Create`/`Update`/`Set` — posting again *replaces* the current username, `Update`
      # would suggest the partial-update semantics of {Profile::Update}, and `Set` would
      # shadow `::Set` inside this namespace.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
      class Claim
        include ActiveModel::Validations
        extend ResponseHandling
        extend Transport

        module Defaults
          EDGE = "username"
          MIN_LENGTH = 3
          MAX_LENGTH = 35
          CHARSET_PATTERN = /\A[a-z0-9._]+\z/
          LETTER_PATTERN = /[a-z]/
          RESERVED_PREFIX = "www"
        end

        # What happens when the username is already in use on another business phone
        # number in the *same* portfolio.
        module TransferActions
          NONE = "none"
          FORCE_TRANSFER = "force_transfer"

          ALL = [NONE, FORCE_TRANSFER].freeze

          # Normalizes caller input to Meta's documented casing, which is lowercase here —
          # unlike this module's other enums. Unrecognized values are returned untouched so
          # the inclusion validator can report them.
          # @param value [String, Symbol, nil]
          # @return [String, nil]
          def self.normalize(value)
            return if value.nil?

            candidate = value.to_s.downcase
            ALL.include?(candidate) ? candidate : value.to_s
          end
        end

        # The domain-like endings Meta lists. **Its list is explicitly open-ended** ("and
        # so on"), so this cannot be complete: a suffix outside it is rejected server-side
        # with error `100` instead. Checked locally anyway, because catching the common
        # cases without spending a rate-limited request is worth more than the false sense
        # of completeness costs.
        DOMAIN_SUFFIXES = %w[.com .org .net .int .edu .gov .mil .us .in .html].freeze

        # @!attribute [rw] username
        #   @return [String] The desired username, downcased.
        attr_accessor :username

        # @!attribute [rw] transfer_action
        #   @return [String] One of {TransferActions::ALL}.
        attr_accessor :transfer_action

        validate :validate_username_format
        validates :username, presence: true
        # Length is nil-exempt so a missing username reports only "can't be blank" — the
        # presence validator above is what must catch nil, and a shared `allow_nil` would
        # have exempted it too.
        validates :username, length: { minimum: Defaults::MIN_LENGTH, maximum: Defaults::MAX_LENGTH },
          allow_nil: true
        validates :transfer_action, inclusion: { in: TransferActions::ALL }

        # @param username [String] The desired username. Meta compares usernames
        #   case-insensitively, so a mixed-case value is downcased here rather than
        #   rejected — `"JaspersMarket"` and `"jaspersmarket"` are the same name, and
        #   refusing one Meta would have accepted is the failure mode this module avoids.
        #   `.` and `_` *are* significant: `myid`, `my.id`, and `my_id` are three names.
        # @param transfer_action [String, Symbol] `"none"` (the default) fails with error
        #   `147005` if another of your numbers holds the name; `"force_transfer"` moves it.
        # @raise [ActiveModel::ValidationError] if the username breaks a documented rule.
        def initialize(username:, transfer_action: TransferActions::NONE)
          @username = username&.to_s&.downcase
          @transfer_action = TransferActions.normalize(transfer_action)

          validate!
        end

        # @return [Hash] The claim payload. `transfer_action` is always sent rather than
        #   compacted away when it is the default: it is a per-request behavior flag, not a
        #   stored field, so convention 7's "nil means leave alone" does not apply — and
        #   sending it explicitly pins the behavior if Meta ever changes its own default,
        #   which matters for an operation whose other value takes a name off another number.
        def serialize
          { username:, transfer_action: }
        end

        class << self
          # @example Move a username onto this number from another of yours
          #   Claim.call(username: "jaspersmarket", transfer_action: :force_transfer)
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @param username [String] See {#initialize}.
          # @param transfer_action [String, Symbol] See {#initialize}.
          # @return [Details] Carrying `status` only; `username` is `nil`, since Meta
          #   answers with the state rather than echoing the name back.
          # @raise [ActiveModel::ValidationError] if the username breaks a documented rule.
          # @raise [Error] if no phone number ID is configured, or the request fails. Error
          #   `147005` means another of your numbers holds the name — retry with
          #   `transfer_action: "force_transfer"`. `147001` means it is unavailable,
          #   `147002` that the portfolio's messaging limit is too low, and
          #   `147003`/`147004` that the number must first be linked to the Facebook Page
          #   or Instagram account already using it.
          def call(username:, client: Client.new, transfer_action: TransferActions::NONE)
            body = new(username:, transfer_action:).serialize
            response = client.connection.post(edge_path(client, Defaults::EDGE), json: body)

            Details.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "claim business username"))
            )
          end
        end

      private

        # Meta's published format rules, minus the open-ended domain-suffix list, which is
        # handled separately.
        # @return [void]
        def validate_username_format
          return if username.nil? || username.empty?

          validate_charset
          validate_has_letter
          validate_period_placement
          validate_not_reserved_prefix
          validate_no_domain_suffix
        end

        # @return [void]
        def validate_charset
          return if username.match?(Defaults::CHARSET_PATTERN)

          errors.add(:username, "may only contain a-z, 0-9, periods and underscores")
        end

        # @return [void]
        def validate_has_letter
          return if username.match?(Defaults::LETTER_PATTERN)

          errors.add(:username, "must contain at least one letter")
        end

        # @return [void]
        def validate_period_placement
          errors.add(:username, "must not start or end with a period") if
            username.start_with?(".") || username.end_with?(".")
          errors.add(:username, "must not contain two consecutive periods") if username.include?("..")
        end

        # Read as Meta writes it: a bare `www` prefix, so `wwwidgets` is rejected too. A
        # local false rejection is cheap and reversible; a wasted request against a rate
        # limited edge is not, and this way the error names the exact rule.
        # @return [void]
        def validate_not_reserved_prefix
          return unless username.start_with?(Defaults::RESERVED_PREFIX)

          errors.add(:username, "must not start with #{Defaults::RESERVED_PREFIX}")
        end

        # @return [void]
        def validate_no_domain_suffix
          suffix = DOMAIN_SUFFIXES.find { |candidate| username.end_with?(candidate) }
          return if suffix.nil?

          errors.add(:username, "must not end with a domain suffix such as #{suffix}")
        end
      end
    end
  end
end

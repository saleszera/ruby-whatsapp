# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Username
      # The username state returned by {Get} and {Claim}.
      #
      # One class for both, rather than a response per endpoint: `GET` answers
      # `{username, status}` and `POST` answers `{status}` — a subset, not a different
      # shape — so `username` simply tolerates being absent, the same way
      # {BusinessPhoneNumber::Response#id} tolerates only ever being set by {VerifyCode}.
      # `DELETE` is the one that genuinely differs, and it reuses
      # {BusinessPhoneNumber::Response} because a bare `{success}` is what that class is for.
      class Details
        # The states Meta's own responses report. Raw strings, never validated on the way
        # in, so a value added later still round-trips — the {Account::Details} convention.
        #
        # The `business_username_updates` webhook reports a third state, `"deleted"`,
        # which no API response here can return; it is deliberately absent rather than
        # listed in an enum the write side cannot produce.
        module Statuses
          APPROVED = "approved"
          RESERVED = "reserved"

          ALL = [APPROVED, RESERVED].freeze
        end

        # @!attribute [rw] username
        #   @return [String, nil] The current username. Omitted by {Claim}, which answers
        #     with a status only — you already hold the name you passed it — and by {Get}
        #     when the number has no username at all.
        attr_accessor :username

        # @!attribute [rw] status
        #   @return [String, nil] One of {Statuses::ALL}.
        attr_accessor :status

        def initialize(username: nil, status: nil)
          @username = username
          @status = status
        end

        # @return [Boolean] Whether the username is live and visible to WhatsApp users.
        def approved?
          status == Statuses::APPROVED
        end

        # @return [Boolean] Whether the username is held for this number but not yet
        #   visible — it becomes visible when Meta makes the feature generally available.
        def reserved?
          status == Statuses::RESERVED
        end

        class << self
          # @param response [Hash, nil] The parsed response body.
          # @return [Details]
          def deserialize(response)
            response ||= {}

            new(username: response["username"], status: response["status"])
          end
        end
      end
    end
  end
end

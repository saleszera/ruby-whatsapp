# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Account
      # The WhatsApp Business Account node returned by {Get}.
      #
      # Only `id` and `name` are documented required; everything else arrives just when
      # asked for via `fields`, so every attribute tolerates being absent. Status values
      # are exposed as raw strings and are never validated on the way in — this is
      # read-side data, and a value Meta adds later must still round-trip. The frozen
      # constant modules below are for comparison, not enforcement, mirroring how
      # {Whatsapp::MessageTemplates::Response::Node} keeps Meta's echoed payloads raw.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/whatsapp-business-account-api
      class Details
        # Meta's review status for the account.
        module ReviewStatuses
          APPROVED = "APPROVED"
          DEFERRED = "DEFERRED"
          PENDING = "PENDING"
          REJECTED = "REJECTED"

          ALL = [APPROVED, DEFERRED, PENDING, REJECTED].freeze
        end

        # Where the account sits in Meta's business verification process.
        module VerificationStatuses
          EXPIRED = "EXPIRED"
          FAILED = "FAILED"
          INELIGIBLE = "INELIGIBLE"
          NOT_VERIFIED = "NOT_VERIFIED"
          PENDING = "PENDING"
          PENDING_NEED_MORE_INFO = "PENDING_NEED_MORE_INFO"
          PENDING_SUBMISSION = "PENDING_SUBMISSION"
          REJECTED = "REJECTED"
          REVOKED = "REVOKED"
          VERIFIED = "VERIFIED"

          ALL = [EXPIRED, FAILED, INELIGIBLE, NOT_VERIFIED, PENDING, PENDING_NEED_MORE_INFO,
                 PENDING_SUBMISSION, REJECTED, REVOKED, VERIFIED,].freeze
        end

        # Who owns the account: your own business, a client's, or a partner acting for one.
        module OwnershipTypes
          CLIENT_OWNED = "CLIENT_OWNED"
          ON_BEHALF_OF = "ON_BEHALF_OF"
          SELF = "SELF"

          ALL = [CLIENT_OWNED, ON_BEHALF_OF, SELF].freeze
        end

        # @!attribute [rw] id
        #   @return [String, nil] The account's unique identifier.
        attr_accessor :id

        # @!attribute [rw] name
        #   @return [String, nil] The account's human-readable name.
        attr_accessor :name

        # @!attribute [rw] timezone_id
        #   @return [String, nil] The account's timezone identifier.
        attr_accessor :timezone_id

        # @!attribute [rw] message_template_namespace
        #   @return [String, nil] The namespace the account's templates live in.
        attr_accessor :message_template_namespace

        # @!attribute [rw] account_review_status
        #   @return [String, nil] One of {ReviewStatuses::ALL}.
        attr_accessor :account_review_status

        # @!attribute [rw] business_verification_status
        #   @return [String, nil] One of {VerificationStatuses::ALL}.
        attr_accessor :business_verification_status

        # @!attribute [rw] country
        #   @return [String, nil] The account's country code.
        attr_accessor :country

        # @!attribute [rw] ownership_type
        #   @return [String, nil] One of {OwnershipTypes::ALL}.
        attr_accessor :ownership_type

        # @!attribute [rw] primary_business_location
        #   @return [String, nil] The account's primary business location.
        attr_accessor :primary_business_location

        # @param id [String, nil]
        # @param name [String, nil]
        # @param timezone_id [String, nil]
        # @param message_template_namespace [String, nil]
        # @param account_review_status [String, nil]
        # @param business_verification_status [String, nil]
        # @param country [String, nil]
        # @param ownership_type [String, nil]
        # @param primary_business_location [String, nil]
        def initialize(id: nil, name: nil, timezone_id: nil, message_template_namespace: nil,
          account_review_status: nil, business_verification_status: nil, country: nil,
          ownership_type: nil, primary_business_location: nil)
          @id = id
          @name = name
          @timezone_id = timezone_id
          @message_template_namespace = message_template_namespace
          @account_review_status = account_review_status
          @business_verification_status = business_verification_status
          @country = country
          @ownership_type = ownership_type
          @primary_business_location = primary_business_location
        end

        class << self
          # @param response [Hash, nil] The parsed response body.
          # @return [Details]
          def deserialize(response)
            response ||= {}

            new(
              id: response["id"],
              name: response["name"],
              timezone_id: response["timezone_id"],
              message_template_namespace: response["message_template_namespace"],
              account_review_status: response["account_review_status"],
              business_verification_status: response["business_verification_status"],
              country: response["country"],
              ownership_type: response["ownership_type"],
              primary_business_location: response["primary_business_location"]
            )
          end
        end

        # @return [Boolean] Whether Meta has approved the account.
        def approved?
          account_review_status == ReviewStatuses::APPROVED
        end

        # @return [Boolean] Whether the business behind the account is verified.
        def verified?
          business_verification_status == VerificationStatuses::VERIFIED
        end

        # @return [Boolean] Whether the account belongs to your own business, rather
        #   than to a client or a partner acting on one's behalf.
        def self_owned?
          ownership_type == OwnershipTypes::SELF
        end
      end
    end
  end
end

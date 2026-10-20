# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module ContactBook
      # Deletes one user's entry from your contact book.
      #
      # A validated instance rather than a bare class method: Meta documents a rule this
      # can check — parent BSUIDs are not accepted here — and the edge is rate limited, so
      # a request that was never going to be accepted should not be spent.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
      class Delete
        include ActiveModel::Validations
        extend ResponseHandling
        extend Transport

        module Defaults
          EDGE = "contact_book"
          MESSAGING_PRODUCT = "whatsapp"
          # A parent BSUID carries an extra segment (`US.ENT.118...`) where a standard one
          # has just the country code and identifier (`US.134...`), so counting separators
          # distinguishes them without asserting a country-code grammar Meta has not
          # published. See {#validate_standard_bsuid}.
          PARENT_SEPARATOR_COUNT = 1
        end

        # @!attribute [rw] bsuid
        #   @return [String] The business-scoped user ID whose entry to remove.
        attr_accessor :bsuid

        validate :validate_standard_bsuid
        validates :bsuid, presence: true

        # @param bsuid [String] The user's standard BSUID, e.g.
        #   `"US.13491208655302741918"`. Must belong to the same business portfolio as the
        #   phone number — Meta checks that server-side, since it is account state this gem
        #   cannot see. Parent BSUIDs are not supported and are rejected locally.
        # @raise [ActiveModel::ValidationError] if the BSUID is missing or looks like a parent.
        def initialize(bsuid:)
          @bsuid = bsuid

          validate!
        end

        # @return [Hash] The query parameters. Sent as a query string rather than a body
        #   because the edge is a `DELETE` — the one action in this directory whose
        #   `#serialize` is not a JSON payload. `messaging_product` is documented required,
        #   so it is always sent.
        def serialize
          { messaging_product: Defaults::MESSAGING_PRODUCT, bsuid: }
        end

        class << self
          # @example Forget a user who asked to be forgotten
          #   ContactBook::Delete.call(bsuid: "US.13491208655302741918")
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @param bsuid [String] See {#initialize}.
          # @return [Deletion] Whose `deleted` is `false` if no entry existed.
          # @raise [ActiveModel::ValidationError] if the BSUID is missing or looks like a parent.
          # @raise [Error] if no phone number ID is configured, or the request fails.
          def call(bsuid:, client: Client.new)
            params = new(bsuid:).serialize
            response = client.connection.delete(edge_path(client, Defaults::EDGE), params:)

            Deletion.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "delete contact book entry"))
            )
          end
        end

      private

        # Meta states plainly that parent BSUIDs are rejected here, and this release hands
        # callers `user_id` and `parent_user_id` side by side on half a dozen webhook
        # classes, so mixing them up is the predictable mistake. Detected by segment count
        # rather than by matching `ENT`, which would bet that `ENT` is the only marker Meta
        # will ever insert — an inference either way, so the weaker one wins.
        # @return [void]
        def validate_standard_bsuid
          return if bsuid.nil? || bsuid.to_s.count(".") <= Defaults::PARENT_SEPARATOR_COUNT

          errors.add(:bsuid, "looks like a parent BSUID; the contact book accepts standard BSUIDs only")
        end
      end
    end
  end
end

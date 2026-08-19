# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Account
      # Updates a WhatsApp Business Account's name or timezone.
      #
      # A validated instance rather than a bare class method (unlike {Get}, which has
      # nothing to check): Meta documents `name` as a non-empty string, and since both
      # fields are optional an all-nil call would spend a request to change nothing.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/whatsapp-business-account-api
      class Update
        include ActiveModel::Validations
        extend ResponseHandling
        extend Transport

        # @!attribute [rw] name
        #   @return [String, nil] The account's new name.
        attr_accessor :name

        # @!attribute [rw] timezone_id
        #   @return [String, nil] The account's new timezone identifier.
        attr_accessor :timezone_id

        validate :validate_any_attribute_present
        validates :name, presence: true, allow_nil: true
        validates :timezone_id, presence: true, allow_nil: true

        # @param name [String, nil] The account's new name. Meta rejects an empty
        #   string, so a blank value fails here rather than at the API.
        # @param timezone_id [String, nil] The account's new timezone identifier. Meta
        #   publishes no enum for this field, so only presence is checked.
        # @raise [ActiveModel::ValidationError] if both are nil, or either is blank.
        def initialize(name: nil, timezone_id: nil)
          @name = name
          @timezone_id = timezone_id

          validate!
        end

        # @return [Hash] The update payload. Both fields are optional, so an omitted
        #   one is compacted away rather than sent as null — which Meta would read as
        #   an instruction to blank it.
        def serialize
          { name:, timezone_id: }.compact
        end

        class << self
          # @param client [Whatsapp::Client] The WhatsApp client instance.
          # @param name [String, nil] See {#initialize}.
          # @param timezone_id [String, nil] See {#initialize}.
          # @return [BusinessPhoneNumber::Response]
          # @raise [ActiveModel::ValidationError] if no attribute is given, or one is blank.
          # @raise [Error] if no WABA ID is configured, or the request fails.
          def call(client: Client.new, name: nil, timezone_id: nil)
            body = new(name:, timezone_id:).serialize
            response = client.connection.post(node_path(client), json: body)

            BusinessPhoneNumber::Response.deserialize(
              parse_json(handle_response!(response, error_class: Error, action: "update business account"))
            )
          end
        end

      private

        # @return [void]
        def validate_any_attribute_present
          return unless name.nil? && timezone_id.nil?

          errors.add(:base, "at least one of name or timezone_id must be provided")
        end
      end
    end
  end
end

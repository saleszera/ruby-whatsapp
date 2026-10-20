# frozen_string_literal: true

module Whatsapp
  module Schedule
    # Schedules an approved template to be sent to an audience at a set time.
    #
    # A validated instance rather than a bare class method (unlike {List}, which has
    # nothing to check): Meta documents all six body fields as required, so a missing
    # one fails here rather than costing a request. Nothing beyond that is checked —
    # Meta publishes no length limits and no rule that `delivery_time` must be in the
    # future.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/schedules-api
    class Create
      include ActiveModel::Validations
      extend ResponseHandling
      extend Transport

      # @!attribute [rw] hsm_id
      #   @return [String] The ID of the approved template to send.
      attr_accessor :hsm_id

      # @!attribute [rw] audience_id
      #   @return [String] The ID of the audience to send it to.
      attr_accessor :audience_id

      # @!attribute [rw] waba_cs_id
      #   @return [String] What Meta documents only as "WABA customer status ID (phone
      #     number)"; whether that means a phone number ID or the number itself is
      #     unverified, so it is passed through as given.
      attr_accessor :waba_cs_id

      # @!attribute [rw] name
      #   @return [String] The schedule's name.
      attr_accessor :name

      # @!attribute [rw] description
      #   @return [String] The schedule's description.
      attr_accessor :description

      # @!attribute [rw] delivery_time
      #   @return [Integer] When to send, as a Unix timestamp.
      attr_accessor :delivery_time

      validates :hsm_id, :audience_id, :waba_cs_id, :name, :description, presence: true
      validates :delivery_time, numericality: { only_integer: true }

      # @param hsm_id [String] See {#hsm_id}.
      # @param audience_id [String] See {#audience_id}.
      # @param waba_cs_id [String] See {#waba_cs_id}.
      # @param name [String] See {#name}.
      # @param description [String] See {#description}.
      # @param delivery_time [Integer] A Unix timestamp; pass `time.to_i` for a `Time`.
      # @raise [ActiveModel::ValidationError] if a field is blank, or `delivery_time`
      #   is not an integer.
      def initialize(hsm_id:, audience_id:, waba_cs_id:, name:, description:, delivery_time:)
        @hsm_id = hsm_id
        @audience_id = audience_id
        @waba_cs_id = waba_cs_id
        @name = name
        @description = description
        @delivery_time = delivery_time

        validate!
      end

      # @return [Hash] The schedule payload. Every field is documented required, so
      #   none is ever compacted away.
      def serialize
        { hsm_id:, audience_id:, waba_cs_id:, name:, description:, delivery_time: }
      end

      class << self
        # @example Send a template to an audience in one hour
        #   Create.call(
        #     hsm_id: "1234567890", audience_id: "2345678901", waba_cs_id: "3456789012",
        #     name: "Black Friday", description: "Black Friday promo to VIP customers",
        #     delivery_time: Time.now.to_i + 3600
        #   ).id
        # @param hsm_id [String] See {#initialize}.
        # @param audience_id [String] See {#initialize}.
        # @param waba_cs_id [String] See {#initialize}.
        # @param name [String] See {#initialize}.
        # @param description [String] See {#initialize}.
        # @param delivery_time [Integer] See {#initialize}.
        # @param client [Whatsapp::Client] The WhatsApp client instance.
        # @return [Response::Created]
        # @raise [ActiveModel::ValidationError] if a field is blank, or `delivery_time`
        #   is not an integer.
        # @raise [Error] if no WABA ID is configured, or the request fails.
        def call(hsm_id:, audience_id:, waba_cs_id:, name:, description:, delivery_time:, client: Client.new)
          body = new(hsm_id:, audience_id:, waba_cs_id:, name:, description:, delivery_time:).serialize
          response = client.connection.post(edge_path(client), json: body)

          Response::Created.deserialize(
            parse_json(handle_response!(response, error_class: Error, action: "create schedule"))
          )
        end
      end
    end
  end
end

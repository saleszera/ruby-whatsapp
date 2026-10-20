# frozen_string_literal: true

module Whatsapp
  module Schedule
    module Response
      # One campaign schedule, as listed by {List}.
      #
      # Every attribute tolerates being absent: Meta returns only the fields asked for,
      # and its default set omits `id`. `status` is kept as the raw string and never
      # validated on the way in; compare it through the predicates or {Statuses}.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/schedules-api
      class Node
        # @!attribute [rw] id
        #   @return [String, nil] The schedule's unique identifier.
        attr_accessor :id

        # @!attribute [rw] name
        #   @return [String, nil] The schedule's name.
        attr_accessor :name

        # @!attribute [rw] description
        #   @return [String, nil] The schedule's description.
        attr_accessor :description

        # @!attribute [rw] delivery_time
        #   @return [Integer, nil] The scheduled delivery time, as a Unix timestamp.
        attr_accessor :delivery_time

        # @!attribute [rw] status
        #   @return [String, nil] One of {Statuses::ALL}.
        attr_accessor :status

        # @param id [String, nil]
        # @param name [String, nil]
        # @param description [String, nil]
        # @param delivery_time [Integer, nil]
        # @param status [String, nil]
        def initialize(id: nil, name: nil, description: nil, delivery_time: nil, status: nil)
          @id = id
          @name = name
          @description = description
          @delivery_time = delivery_time
          @status = status
        end

        class << self
          # @param data [Hash, nil] One element of the `data` array.
          # @return [Node]
          def deserialize(data)
            data ||= {}

            new(
              id: data["id"],
              name: data["name"],
              description: data["description"],
              delivery_time: data["delivery_time"],
              status: data["status"]
            )
          end
        end

        # @return [Boolean] Whether the schedule is still waiting for its delivery time.
        def scheduled?
          status == Statuses::SCHEDULED
        end

        # @return [Boolean] Whether the campaign is being sent right now.
        def sending?
          status == Statuses::SENDING
        end

        # @return [Boolean] Whether the campaign finished sending.
        def completed?
          status == Statuses::COMPLETED
        end

        # @return [Boolean] Whether the campaign failed.
        def failed?
          status == Statuses::FAILED
        end
      end
    end
  end
end

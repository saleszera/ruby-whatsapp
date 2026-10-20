# frozen_string_literal: true

module Whatsapp
  module Schedule
    module Response
      # The response to creating a campaign schedule: `{id}`.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/schedules-api
      class Created
        # @!attribute [rw] id
        #   @return [String, nil] The new schedule's unique identifier.
        attr_accessor :id

        # @param id [String, nil]
        def initialize(id: nil)
          @id = id
        end

        class << self
          # @param data [Hash, nil] The parsed response body.
          # @return [Created]
          def deserialize(data)
            data ||= {}

            new(id: data["id"])
          end
        end
      end
    end
  end
end

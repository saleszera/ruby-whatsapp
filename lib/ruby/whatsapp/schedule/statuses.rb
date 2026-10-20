# frozen_string_literal: true

module Whatsapp
  module Schedule
    # The documented states of a campaign schedule.
    #
    # For comparison, not enforcement: {Response::Node#status} keeps whatever string
    # Meta sends, so a status added later still round-trips.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/schedules-api
    module Statuses
      COMPLETED = "COMPLETED"
      FAILED = "FAILED"
      SCHEDULED = "SCHEDULED"
      SENDING = "SENDING"

      ALL = [COMPLETED, FAILED, SCHEDULED, SENDING].freeze
    end
  end
end

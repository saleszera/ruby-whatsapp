# frozen_string_literal: true

module Whatsapp
  module Webhook
    # A business phone number's username status changed — approved, reserved, or deleted.
    # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
    class BusinessUsernameUpdates
      # @!attribute [rw] display_phone_number
      #   @return [String, nil]
      attr_accessor :display_phone_number

      # @!attribute [rw] username
      #   @return [String, nil] Omitted when `status` is `"deleted"`.
      attr_accessor :username

      # @!attribute [rw] status
      #   @return [String, nil] `"approved"`, `"reserved"`, or `"deleted"`.
      attr_accessor :status

      def initialize(display_phone_number:, username:, status:)
        @display_phone_number = display_phone_number
        @username = username
        @status = status
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [BusinessUsernameUpdates]
        def deserialize(data)
          data ||= {}

          new(
            display_phone_number: data["display_phone_number"],
            username: data["username"],
            status: data["status"]
          )
        end
      end
    end
  end
end

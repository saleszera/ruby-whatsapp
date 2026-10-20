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

      # @!attribute [r] raw
      #   @return [Hash] The untouched `value` hash. A diagnostic escape hatch, not part
      #     of the supported API: every attribute above is a flat top-level read, so a
      #     single renamed key yields an all-`nil` object with no other signal. Reach for
      #     it when a typed accessor is unexpectedly `nil`, log what you find, and treat
      #     it as read-only: it is the object `JSON.parse` returned, not a copy.
      attr_reader :raw

      def initialize(display_phone_number: nil, status: nil, username: nil, raw: {})
        @display_phone_number = display_phone_number
        @username = username
        @status = status
        @raw = raw
      end

      class << self
        # @param data [Hash] The raw `value` hash.
        # @return [BusinessUsernameUpdates]
        def deserialize(data)
          data ||= {}

          new(
            display_phone_number: data["display_phone_number"],
            username: data["username"],
            status: data["status"],
            raw: data
          )
        end
      end
    end
  end
end

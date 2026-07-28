# frozen_string_literal: true

module Whatsapp
  module Webhook
    class AccountUpdate
      # The ban details attached to an `account_update` notification.
      class BanInfo
        # @!attribute [rw] waba_ban_state
        #   @return [String, nil]
        attr_accessor :waba_ban_state

        # @!attribute [rw] waba_ban_date
        #   @return [String, nil]
        attr_accessor :waba_ban_date

        def initialize(waba_ban_state:, waba_ban_date:)
          @waba_ban_state = waba_ban_state
          @waba_ban_date = waba_ban_date
        end

        class << self
          # @param data [Hash] The raw `ban_info` hash.
          # @return [BanInfo]
          def deserialize(data)
            data ||= {}

            new(waba_ban_state: data["waba_ban_state"], waba_ban_date: data["waba_ban_date"])
          end
        end
      end
    end
  end
end

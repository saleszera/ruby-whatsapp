# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      class Contacts < Base
        # A phone number entry within an inbound contact card.
        class Phone
          # @!attribute [rw] phone
          #   @return [String, nil]
          attr_accessor :phone

          # @!attribute [rw] type
          #   @return [String, nil]
          attr_accessor :type

          # @!attribute [rw] wa_id
          #   @return [String, nil]
          attr_accessor :wa_id

          def initialize(phone:, type: nil, wa_id: nil)
            @phone = phone
            @type = type
            @wa_id = wa_id
          end

          class << self
            # @param data [Hash] A raw `phones[]` entry.
            # @return [Phone]
            def deserialize(data)
              data ||= {}

              new(phone: data["phone"], type: data["type"], wa_id: data["wa_id"])
            end
          end
        end
      end
    end
  end
end

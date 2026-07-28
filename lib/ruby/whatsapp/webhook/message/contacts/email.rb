# frozen_string_literal: true

module Whatsapp
  module Webhook
    class Message
      class Contacts < Base
        # An email entry within an inbound contact card.
        class Email
          # @!attribute [rw] email
          #   @return [String, nil]
          attr_accessor :email

          # @!attribute [rw] type
          #   @return [String, nil]
          attr_accessor :type

          def initialize(email:, type: nil)
            @email = email
            @type = type
          end

          class << self
            # @param data [Hash] A raw `emails[]` entry.
            # @return [Email]
            def deserialize(data)
              data ||= {}

              new(email: data["email"], type: data["type"])
            end
          end
        end
      end
    end
  end
end

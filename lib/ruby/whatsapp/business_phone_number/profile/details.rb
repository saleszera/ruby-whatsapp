# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Profile
      # The business profile returned by {Get}.
      #
      # Every field arrives only when asked for via `fields`, so every attribute tolerates
      # being absent. Nothing is validated or normalized on the way in — this is read-side
      # data, and a `vertical` Meta adds later must still round-trip untouched. Compare
      # against {Verticals::ALL} rather than expecting this class to have rejected an unknown
      # value, the same reasoning as {Account::Details}' statuses and
      # {Whatsapp::MessageTemplates::Response::Node}'s raw components.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/whatsapp-business-profile-api
      class Details
        # @!attribute [rw] messaging_product
        #   @return [String, nil] The messaging service, always `"whatsapp"` in practice.
        attr_accessor :messaging_product

        # @!attribute [rw] about
        #   @return [String, nil] The text shown in the profile's About section.
        attr_accessor :about

        # @!attribute [rw] address
        #   @return [String, nil] The business's physical address.
        attr_accessor :address

        # @!attribute [rw] description
        #   @return [String, nil] The business description.
        attr_accessor :description

        # @!attribute [rw] email
        #   @return [String, nil] The business's contact email address.
        attr_accessor :email

        # @!attribute [rw] profile_picture_url
        #   @return [String, nil] The URL of the profile picture.
        attr_accessor :profile_picture_url

        # @!attribute [rw] websites
        #   @return [Array<String>, nil] The business's website URLs.
        attr_accessor :websites

        # @!attribute [rw] vertical
        #   @return [String, nil] One of {Verticals::ALL}, as sent by Meta.
        attr_accessor :vertical

        # @param messaging_product [String, nil]
        # @param about [String, nil]
        # @param address [String, nil]
        # @param description [String, nil]
        # @param email [String, nil]
        # @param profile_picture_url [String, nil]
        # @param websites [Array<String>, nil]
        # @param vertical [String, nil]
        def initialize(messaging_product: nil, about: nil, address: nil, description: nil,
          email: nil, profile_picture_url: nil, websites: nil, vertical: nil)
          @messaging_product = messaging_product
          @about = about
          @address = address
          @description = description
          @email = email
          @profile_picture_url = profile_picture_url
          @websites = websites
          @vertical = vertical
        end

        class << self
          # @param response [Hash, nil] The parsed response body, envelope included.
          # @return [Details]
          def deserialize(response)
            profile = unwrap(response)

            new(
              messaging_product: profile["messaging_product"],
              about: profile["about"],
              address: profile["address"],
              description: profile["description"],
              email: profile["email"],
              profile_picture_url: profile["profile_picture_url"],
              websites: profile["websites"],
              vertical: profile["vertical"]
            )
          end

        private

          # Digs the profile out of Meta's `data` envelope.
          #
          # The reference documents the entry as wrapping the profile in `business_profile`,
          # while live responses are observed to carry the fields directly; both are read
          # rather than betting on one. Only the first entry matters — a phone number has
          # exactly one profile.
          # @param response [Hash, nil]
          # @return [Hash]
          def unwrap(response)
            entry = Array((response || {})["data"]).first || {}

            entry["business_profile"] || entry
          end
        end
      end
    end
  end
end

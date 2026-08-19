# frozen_string_literal: true

module Whatsapp
  module BusinessPhoneNumber
    module Profile
      # The industry verticals Meta publishes for a business profile.
      #
      # Its own file rather than nested inside {Update}, since two classes use it: {Update}
      # validates against it and {Details} exposes the raw value for comparison against it.
      # That follows {Whatsapp::MessageTemplates::Categories}' precedent rather than
      # {Register::DataLocalizationRegions}', which has a single consumer.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-phone-number/whatsapp-business-profile-api
      module Verticals
        ALCOHOL = "ALCOHOL"
        APPAREL = "APPAREL"
        AUTO = "AUTO"
        BEAUTY = "BEAUTY"
        EDU = "EDU"
        ENTERTAIN = "ENTERTAIN"
        EVENT_PLAN = "EVENT_PLAN"
        FINANCE = "FINANCE"
        GOVT = "GOVT"
        GROCERY = "GROCERY"
        HEALTH = "HEALTH"
        HOTEL = "HOTEL"
        NONPROFIT = "NONPROFIT"
        ONLINE_GAMBLING = "ONLINE_GAMBLING"
        OTC_DRUGS = "OTC_DRUGS"
        OTHER = "OTHER"
        PHYSICAL_GAMBLING = "PHYSICAL_GAMBLING"
        PROF_SERVICES = "PROF_SERVICES"
        RESTAURANT = "RESTAURANT"
        RETAIL = "RETAIL"
        TRAVEL = "TRAVEL"

        ALL = [ALCOHOL, APPAREL, AUTO, BEAUTY, EDU, ENTERTAIN, EVENT_PLAN, FINANCE, GOVT,
               GROCERY, HEALTH, HOTEL, NONPROFIT, ONLINE_GAMBLING, OTC_DRUGS, OTHER,
               PHYSICAL_GAMBLING, PROF_SERVICES, RESTAURANT, RETAIL, TRAVEL,].freeze

        # Normalizes caller input to a canonical uppercase vertical.
        # Unrecognized values are returned untouched so the inclusion validator can
        # report them, matching {Register::DataLocalizationRegions.normalize}.
        # @param value [String, Symbol, nil]
        # @return [String, nil]
        def self.normalize(value)
          return if value.nil?

          candidate = value.to_s.upcase
          ALL.include?(candidate) ? candidate : value.to_s
        end
      end
    end
  end
end

# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    module Response
      # The apps currently subscribed to a WABA's webhook notifications: `{data}`.
      #
      # Enumerable over its apps, so `list.map(&:name)` reads naturally without
      # reaching for `.data` first.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/reference/whatsapp-business-account/subscribed-apps-api
      class Collection
        include Enumerable

        # @!attribute [rw] data
        #   @return [Array<App>]
        attr_accessor :data

        # @param data [Array<App>]
        def initialize(data: [])
          @data = data
        end

        class << self
          # @param response [Hash, nil] The parsed response body.
          # @return [Collection]
          def deserialize(response)
            response ||= {}

            new(data: Array(response["data"]).map { |entry| App.deserialize(entry) })
          end
        end

        # @yieldparam app [App]
        # @return [Enumerator]
        def each(&)
          data.each(&)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Whatsapp
  module SubscribedApp
    # Deserializers for the responses of the `subscribed_apps` edge.
    #
    # Three response shapes, one per action, so a namespace of small classes rather
    # than a single one with optional fields:
    #
    #   {Collection}     `{data}`            List
    #   {Subscription}   `{success, data}`   Subscribe
    #   {Unsubscription} `{success}`         Unsubscribe
    #
    # Every class follows the gem's `.deserialize(data)` convention and tolerates a nil
    # or partial payload, so a field Meta stops sending cannot raise.
    module Response
    end
  end
end

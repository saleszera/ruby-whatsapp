# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      # Asks the recipient to share their phone number, which they hand over with one tap.
      #
      # The interactive-message counterpart to
      # {Whatsapp::MessageTemplates::Button::RequestContactInfo}: use this inside the
      # 24-hour service window, and the template button to open a conversation. Either way
      # this is how you get a phone number back from someone who has adopted a username and
      # reaches you only as a
      # [BSUID](https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids).
      #
      # The only action kind with nothing for the caller to supply — the whole payload is
      # `{ name: "request_contact_info" }` — which is why {Interactive} marks it
      # parameterless and stops requiring an `action:`. Compare
      # {Whatsapp::Messages::LocationRequest}, whose action is the same shape.
      # Source: https://developers.facebook.com/documentation/business-messaging/whatsapp/business-scoped-user-ids
      class RequestContactInfo < Base
        module Defaults
          ACTION_NAME = "request_contact_info"
        end

        # @!attribute [rw] name
        #   @return [String] Always {Defaults::ACTION_NAME}.
        attr_accessor :name

        validates :name, inclusion: { in: [Defaults::ACTION_NAME] }

        # @param name [String] The action name. Defaulted, since Meta accepts exactly one
        #   value; the keyword exists so a caller spelling out
        #   `action: { name: "request_contact_info" }` — mirroring Meta's example payload —
        #   still works.
        #  @raise [ActiveModel::ValidationError] if `name` is anything else.
        def initialize(name: Defaults::ACTION_NAME)
          @name = name

          validate!
        end

        class << self
          # Takes a keyword splat rather than named parameters, because {Interactive} calls
          # it as `serialize(**action)` with an empty hash for this kind.
          # @return [Hash] Serialized representation of the request.
          def serialize(**)
            new(**).serialize
          end
        end

        # @return [Hash] Serialized representation of the request — no `parameters` key,
        #   unlike every other action kind, because there is nothing to parameterize.
        def serialize
          { name: }
        end
      end
    end
  end
end

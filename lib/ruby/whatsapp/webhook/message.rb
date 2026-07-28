# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Dispatches a single `messages[]` entry from the `messages` webhook field to
    # the class matching its `type`. Mirrors `Whatsapp::Messages::KINDS` — resolution
    # goes through this frozen whitelist (never `const_get` on the `type` string,
    # which comes straight from the internet), so an unrecognized type falls back to
    # {Message::Unknown} rather than raising.
    class Message
      MESSAGE_TYPES = {
        text: Text,
        image: Image,
        video: Video,
        audio: Audio,
        document: Document,
        sticker: Sticker,
        location: Location,
        contacts: Contacts,
        interactive: Interactive,
        button: Button,
        order: Order,
        system: System,
        reaction: Reaction,
      }.freeze

      class << self
        # @param data [Hash] A raw `messages[]` entry.
        # @return [Message::Base] One of the classes in {MESSAGE_TYPES}, or {Message::Unknown}.
        def deserialize(data)
          data ||= {}
          klass = MESSAGE_TYPES.fetch(data["type"].to_s.to_sym) { Unknown }

          klass.deserialize(data)
        end
      end
    end
  end
end

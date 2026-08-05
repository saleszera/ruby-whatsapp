# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    class Button
      # Shared behaviour for every button a template can declare.
      #
      # Each subclass owns its own wire type as `Defaults::TYPE` rather than having it
      # supplied by the {Button::TYPES} registry — a button's type is intrinsic to the
      # button, so keeping it on the class means one source of truth for both
      # serialization and the per-type cap checks in {Component::Buttons}.
      class Base
        include ValueObject

        # Character limit shared by every button that carries a tappable label.
        MAX_TEXT_LENGTH = 25

        # The uppercase value Meta expects in the button's `type` field.
        # @return [String]
        def api_type
          self.class::Defaults::TYPE
        end
      end
    end
  end
end

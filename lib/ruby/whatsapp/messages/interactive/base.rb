# frozen_string_literal: true

module Whatsapp
  class Messages
    class Interactive
      class Base
        include ActiveModel::Validations

        def serialize
          raise NotImplementedError, "Subclasses must implement the serialize method"
        end
      end
    end
  end
end

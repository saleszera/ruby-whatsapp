# frozen_string_literal: true

module Whatsapp
  module Schedule
    # Deserializers for the responses of the `schedules` edge.
    #
    # Two response shapes, one per action, plus the element type of the list:
    #
    #   {Collection}   `{data, paging}`   List
    #   {Created}      `{id}`             Create
    #   {Node}         one element of `data`
    #
    # Every class follows the gem's `.deserialize(data)` convention and tolerates a nil
    # or partial payload, so a field Meta stops sending cannot raise.
    module Response
    end
  end
end

# frozen_string_literal: true

module Whatsapp
  class MessageTemplates
    # Deserializers for the responses of the template-management edge.
    #
    # Unlike {Whatsapp::Messages::Response}, which parses one shape, this edge answers
    # in four different ones depending on the operation — hence a namespace of small
    # classes rather than a single one with optional fields:
    #
    #   {Created}    `{id, status, category}`        create, create_from_library, upsert
    #   {Node}       the full template object        find, and each element of a list
    #   {Collection} `{data, paging, summary}`       list
    #   —            `{success: true}`               update and delete, returned as a
    #                                                plain boolean, as {Media#delete} does
    #
    # Every class follows the gem's `.deserialize(data)` convention and tolerates a nil
    # or partial payload, so a field Meta stops sending cannot raise.
    module Response
    end
  end
end

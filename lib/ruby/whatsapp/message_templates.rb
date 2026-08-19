# frozen_string_literal: true

module Whatsapp
  # Manages the message templates on a WhatsApp Business Account: create, list, read,
  # edit, and delete.
  #
  # This is the opposite side of {Whatsapp::Messages::Template}, which *sends* an
  # already-approved template. The two are separate APIs with incompatible payload
  # schemas — different endpoint, different ID (`waba_id`, not `phone_id`), different
  # permission (`whatsapp_business_management`), and components that carry `text` plus
  # an `example` here versus `parameters` when sending. See
  # `lib/ruby/whatsapp/message_templates/CLAUDE.md`.
  #
  # This class is only the transport: it builds paths, issues requests, and hands the
  # bodies to {Response}. Every rule about what a valid template looks like lives in
  # {Template} / {ComponentSet} / {Component} / {Button}, so nothing here needs to know
  # what a carousel is.
  #
  # @example
  #   templates = Whatsapp::MessageTemplates.new
  #   created = templates.create(
  #     name: "order_confirmation", language: "en_US", category: "UTILITY",
  #     components: [{ type: :body, text: "Thanks, {{1}}!", example: ["Pablo"] }]
  #   )
  #   templates.find(template_id: created.id).status # => "PENDING"
  # Source: https://developers.facebook.com/docs/graph-api/reference/whats-app-business-account/message_templates/
  class MessageTemplates
    include PathBuilding
    include ResponseHandling

    class TemplateError < Whatsapp::Error; end

    # The API edges these operations address.
    module Edges
      MESSAGE_TEMPLATES = "message_templates"
      UPSERT_MESSAGE_TEMPLATES = "upsert_message_templates"
    end

    module Defaults
      # Meta's cap on a single bulk delete.
      MAX_DELETE_IDS = 100
      # Filters whose value is a list of names rather than a JSON array.
      COMMA_JOINED_FILTERS = [:fields].freeze
    end

    # @!attribute [rw] client
    #   @return [Whatsapp::Client]
    attr_accessor :client

    # @param client [Whatsapp::Client] The WhatsApp client instance.
    def initialize(client: Client.new)
      @client = client
    end

    # Creates a template.
    #
    # Validation happens before the request, so an invalid template costs nothing. The
    # response `status` is usually PENDING — Meta reviews templates asynchronously and
    # reports the outcome via the `message_template_status_update` webhook.
    # @param attrs [Hash] Forwarded to {Template} (`name:`, `language:`, `category:`,
    #   `components:`, and the optional fields).
    # @return [Response::Created]
    # @raise [ActiveModel::ValidationError] if the template is invalid.
    # @raise [TemplateError] if the request fails.
    def create(**attrs)
      created_from(edge_path(Edges::MESSAGE_TEMPLATES), Template.new(**attrs), action: "create template")
    end

    # Creates a template by cloning one of Meta's pre-written library templates.
    #
    # Uses the same edge as {#create} but a different payload — no components, just the
    # library template's name and the inputs that customise it. Library templates are
    # pre-categorised and pre-reviewed, so the response is usually APPROVED immediately.
    # @param attrs [Hash] Forwarded to {LibraryTemplate}.
    # @return [Response::Created]
    # @raise [ActiveModel::ValidationError] if the payload is invalid.
    # @raise [TemplateError] if the request fails.
    def create_from_library(**attrs)
      created_from(
        edge_path(Edges::MESSAGE_TEMPLATES), LibraryTemplate.new(**attrs),
        action: "create template from library"
      )
    end

    # Creates or updates the same template across several languages in one call.
    #
    # Matching is on `(name, language)`: an existing pair is updated, a missing one is
    # created. Primarily documented for authentication templates.
    # @param attrs [Hash] Forwarded to {Template}; must include `languages:`.
    # @return [Response::Created]
    # @raise [TemplateError] if `languages:` is missing or the request fails.
    # @raise [ActiveModel::ValidationError] if the template is invalid.
    def upsert(**attrs)
      if blank_value?(attrs[:languages])
        raise TemplateError, "#upsert requires `languages:` (an array of locale codes); use #create for a single one"
      end

      created_from(
        edge_path(Edges::UPSERT_MESSAGE_TEMPLATES), Template.new(**attrs), action: "upsert templates"
      )
    end

    # Lists the account's templates.
    #
    # @param filters [Hash] Any documented filter: `name`, `name_or_content`, `content`,
    #   `language`, `category`, `status`, `quality_score`, `since`, `until`, `fields`,
    #   `limit`, `after`, `before`. Array values are encoded for you.
    # @return [Response::Collection] Enumerable over the templates on this page.
    # @raise [TemplateError] if the request fails.
    def list(**filters)
      response = client.connection.get(edge_path(Edges::MESSAGE_TEMPLATES), params: encode_filters(filters))

      Response::Collection.deserialize(
        parse_json(handle_response!(response, error_class: TemplateError, action: "list templates"))
      )
    end

    # Reads a single template by ID.
    # @param template_id [String] The template's numeric ID.
    # @param fields [Array<String>, String, nil] Restrict the response to these fields.
    # @return [Response::Node]
    # @raise [TemplateError] if the id is missing or the request fails.
    def find(template_id:, fields: nil)
      raise TemplateError, "template_id can't be blank" if blank_value?(template_id)

      response = client.connection.get(
        client.path_for(template_id), params: encode_filters(fields:)
      )

      Response::Node.deserialize(
        parse_json(handle_response!(response, error_class: TemplateError, action: "find template"))
      )
    end

    # Edits a template.
    #
    # Only `category`, `components` and `message_send_ttl_seconds` are editable, and
    # `components` is a **full replacement** — Meta has no way to patch one component.
    # The edit goes to the template's own ID with POST; PUT and PATCH are not supported
    # on this edge.
    #
    # Two limits cannot be checked locally, so they surface as API errors: only
    # APPROVED, REJECTED and PAUSED templates may be edited (see {Response::Node#editable?}),
    # and an approved template allows 10 edits per 30 days and 1 per 24 hours. Editing an
    # approved template also re-submits it for review, though it keeps working meanwhile.
    #
    # @param template_id [String] The template's numeric ID.
    # @param category [String, Symbol, nil] Cannot be changed on an APPROVED template.
    # @param components [Array<Hash, Component::Base>, nil] The full replacement set.
    # @param message_send_ttl_seconds [Integer, nil]
    # @param parameter_format [String, Symbol] Used to build and validate `components`
    #   locally; not sent, since Meta does not list it as editable.
    # @return [Boolean] Whether the API reported success.
    # @raise [TemplateError] if there is nothing to update, or the request fails.
    # @raise [ActiveModel::ValidationError] if the replacement components are invalid.
    def update(template_id:, category: nil, components: nil, message_send_ttl_seconds: nil,
      parameter_format: ParameterFormats::POSITIONAL)
      raise TemplateError, "template_id can't be blank" if blank_value?(template_id)

      payload = update_payload(category:, components:, message_send_ttl_seconds:, parameter_format:)
      raise TemplateError, "nothing to update: pass category, components or message_send_ttl_seconds" if payload.empty?

      response = client.connection.post(client.path_for(template_id), json: payload)

      success?(handle_response!(response, error_class: TemplateError, action: "update template"))
    end

    # Deletes templates.
    #
    # Three mutually exclusive ways to address them, and the choice matters:
    #
    #   `name:` alone   — deletes **every language variant** with that name
    #   `hsm_id:`       — one template; Meta's docs pass `name:` alongside it
    #   `hsm_ids:`      — up to 100 templates, and cannot be mixed with the other two
    #
    # Deleting an approved template blocks reuse of its name for 30 days, and messages
    # already in flight get a 30-day delivery window under the PENDING_DELETION status.
    # DISABLED templates cannot be deleted at all.
    #
    # @param name [String, nil] The template name.
    # @param hsm_id [String, nil] A single template ID.
    # @param hsm_ids [Array<String>, nil] Up to 100 template IDs.
    # @return [Boolean] Whether the API reported success.
    # @raise [TemplateError] if the arguments are unusable, or the request fails.
    def delete(name: nil, hsm_id: nil, hsm_ids: nil)
      params = delete_params(name:, hsm_id:, hsm_ids:)

      response = client.connection.delete(edge_path(Edges::MESSAGE_TEMPLATES), params:)

      success?(handle_response!(response, error_class: TemplateError, action: "delete template"))
    end

  private

    # Posts a serialized payload and deserializes the create-style response.
    # @return [Response::Created]
    def created_from(path, payload, action:)
      response = client.connection.post(path, json: payload.serialize)

      Response::Created.deserialize(
        parse_json(handle_response!(response, error_class: TemplateError, action:))
      )
    end

    # @return [String] The versioned path for a WABA-scoped edge.
    # @raise [TemplateError] if no WABA ID is configured.
    def edge_path(edge)
      scoped_path(client, :waba_id, edge, error_class: TemplateError, purpose: "template management")
    end

    # @return [Hash] Only the editable fields that were supplied.
    def update_payload(category:, components:, message_send_ttl_seconds:, parameter_format:)
      {
        category: Categories.normalize(category),
        components: components && ComponentSet.new(
          components:, category: Categories.normalize(category), parameter_format:
        ).serialize,
        message_send_ttl_seconds:,
      }.compact
    end

    # @return [Hash] The delete query parameters.
    # @raise [TemplateError] if the addressing modes are unusable.
    def delete_params(name:, hsm_id:, hsm_ids:)
      return single_delete_params(name:, hsm_id:) if blank_value?(hsm_ids)

      unless blank_value?(name) && blank_value?(hsm_id)
        raise TemplateError, "hsm_ids cannot be combined with name or hsm_id"
      end

      if hsm_ids.size > Defaults::MAX_DELETE_IDS
        raise TemplateError, "#delete accepts at most #{Defaults::MAX_DELETE_IDS} hsm_ids, got #{hsm_ids.size}"
      end

      # Meta documents this as `hsm_ids=[123,456]` — bare numbers, not a quoted
      # JSON array of strings.
      { hsm_ids: "[#{hsm_ids.join(',')}]" }
    end

    # @return [Hash]
    # @raise [TemplateError] if neither addressing field was given.
    def single_delete_params(name:, hsm_id:)
      raise TemplateError, "#delete requires name, hsm_id or hsm_ids" if blank_value?(name) && blank_value?(hsm_id)

      { name:, hsm_id: }.compact
    end

    # Graph API wants array filters as JSON arrays in the query string, not the
    # `key[]=value` form an HTTP library would produce by default. `fields` is the
    # exception: it is a comma-separated list.
    # @return [Hash]
    def encode_filters(filters)
      filters.compact.to_h do |key, value|
        [key, encode_filter_value(key, value)]
      end
    end

    # @return [Object]
    def encode_filter_value(key, value)
      return value unless value.is_a?(Array)
      return value.join(",") if Defaults::COMMA_JOINED_FILTERS.include?(key)

      value.to_json
    end

    # @return [Boolean] The `{ "success": true }` flag, as {Whatsapp::Media#delete} does.
    def success?(response)
      parsed = parse_json(response)

      parsed.is_a?(Hash) && parsed["success"] == true
    end

    # Plain-Ruby blank check; see the note in {ValueObject#blank_value?}.
    # @return [Boolean]
    def blank_value?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end
  end
end

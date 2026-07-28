# frozen_string_literal: true

module Whatsapp
  class Messages
    include ResponseHandling

    # Maps a public message kind to its implementing class. Resolution goes
    # through this frozen whitelist (never `const_get` on caller input), so an
    # unknown or hostile `kind` can only raise, never resolve an arbitrary
    # constant.
    KINDS = {
      text: Text,
      image: Image,
      audio: Audio,
      video: Video,
      document: Document,
      sticker: Sticker,
      contacts: Contacts,
      reaction: Reaction,
      location: Location,
      address: Address,
      location_request: LocationRequest,
      template: Template,
      interactive: Interactive,
    }.freeze

    class << self
      # Defines a `send_<kind>!` convenience class method for every kind in
      # KINDS (e.g. `send_text!`, `send_template!`), equivalent to
      # `new(kind:, payload:, client:).send!`. Adding a kind to KINDS above
      # automatically gets one of these for free.
      KINDS.each_key do |kind|
        define_method(:"send_#{kind}!") do |client: Client.new, **payload|
          new(kind:, payload:, client:).send!
        end
      end
    end

    class PayloadError < Whatsapp::Error; end

    # @!attribute [rw] payload
    #   @return [Whatsapp::Messages::Base]
    attr_accessor :payload

    # @!attribute [rw] client
    #   @return [Whatsapp::Client]
    attr_accessor :client

    # @param kind [Symbol, String] The type of message (e.g., :text, :template)
    # @param payload [Hash] The message payload passed to the message class
    # @param client [Whatsapp::Client] The WhatsApp client instance
    # @raise [PayloadError] if the kind is unknown
    def initialize(kind:, payload:, client: Client.new)
      klass = KINDS.fetch(kind.to_sym) do
        raise PayloadError, "Unknown message kind: #{kind.inspect}. Known kinds: #{KINDS.keys.join(', ')}"
      end

      @payload = klass.new(**payload)
      @client = client
    end

    # Sends the message to the WhatsApp API.
    #   @return [Whatsapp::Messages::Response] The response from the API
    #   @raise [Whatsapp::Messages::PayloadError] if the payload is invalid
    #   @raise [Whatsapp::RequestError] if the request fails
    def send!
      raise PayloadError, "Invalid message: #{payload.errors.full_messages.join(', ')}" unless payload.valid?

      response = perform_request!
      parse!(response)
    end

  private

    # Performs the HTTP request to send the message.
    #   @return [HTTP::Response] The successful HTTP response from the API
    #   @raise [Whatsapp::RequestError] if the request fails
    def perform_request!
      response = client.connection.post(
        client.path_for(client.phone_id, "messages"),
        json: payload.serialize
      )

      handle_response!(response, error_class: RequestError, action: "send message")
    end

    # Parses the HTTP response into a Whatsapp::Messages::Response object.
    #   @param response [HTTP::Response] The HTTP response from the API
    #   @return [Whatsapp::Messages::Response] The parsed response object
    def parse!(response)
      Response.deserialize(response.parse)
    end
  end
end

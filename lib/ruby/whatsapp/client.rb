# frozen_string_literal: true

module Whatsapp
  class Client
    # Default request timeout in seconds.
    DEFAULT_TIMEOUT = 30

    # @!attribute [rw] host
    # @return [String]
    attr_accessor :host

    # @!attribute [rw] version
    # @return [String]
    attr_accessor :version

    # @!attribute [rw] api_key
    # @return [String]
    attr_accessor :api_key

    # @!attribute [rw] phone_id
    # @return [String]
    attr_accessor :phone_id

    # @!attribute [rw] waba_id
    #   The WhatsApp Business Account ID. Used by account-scoped endpoints such as
    #   template management, which address the WABA rather than a phone number.
    #   @return [String, nil]
    attr_accessor :waba_id

    # @param host [String] The API origin (e.g. "https://graph.facebook.com")
    # @param version [String] The API version (e.g. "v24.0")
    # @param api_key [String] The API key for authentication
    # @param phone_id [String] The WhatsApp phone number ID
    # @param waba_id [String] The WhatsApp Business Account ID
    # @param timeout [Integer] The request timeout in seconds
    # @param logger [Logger, nil] The logger instance for instrumentation (optional)
    def initialize(
      host: Whatsapp.configuration.host,
      version: Whatsapp.configuration.version,
      api_key: Whatsapp.configuration.api_key,
      phone_id: Whatsapp.configuration.phone_id,
      waba_id: Whatsapp.configuration.waba_id,
      timeout: DEFAULT_TIMEOUT,
      logger: nil
    )
      @host = host
      @version = version
      @api_key = api_key
      @phone_id = phone_id
      @waba_id = waba_id
      @timeout = timeout
      @logger = logger
    end

    # Sets up and returns the persistent HTTP client, authenticated and instrumented.
    #
    # The persistent base is the origin only — `HTTP.persistent` normalizes its
    # argument to the origin, so the API version must NOT be baked into it or it
    # is silently dropped. The version is carried per-request via {#path_for}.
    # @return [HTTP::Client] The configured HTTP client
    def connection
      @connection ||= begin
        http = HTTP.persistent(@host)
        http = http.auth("Bearer #{@api_key}") if @api_key
        http = http.use(instrumentation: { instrumenter: Instrumentation.new(@logger) }) if @logger
        http = http.timeout(@timeout) if @timeout

        http
      end
    end

    # Builds a versioned request path.
    # @example
    #   path_for(phone_id, "messages") #=> "/v24.0/<phone_id>/messages"
    #   path_for(media_id)             #=> "/v24.0/<media_id>"
    # @param segments [Array<String>] Path segments appended after the version.
    # @return [String] The full request path.
    def path_for(*segments)
      "/#{[version, *segments].join('/')}"
    end
  end
end

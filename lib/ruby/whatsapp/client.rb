# frozen_string_literal: true

module Whatsapp
  class Client
    # @!attribute [rw] host
    # @return [String]
    attr_accessor :host

    # @!attribute [rw] version
    # @return [String]
    attr_accessor :version

    # @!attribute [rw] api_key
    # @return [String]
    attr_accessor :api_key


    # @param host [String] The API host URL
    # @param version [String] The API version
    # @param api_key [String] The API key for authentication
    # @param timeout [Integer, nil] The request timeout in seconds (optional)
    # @param logger [Logger, nil] The logger instance for instrumentation (optional)
    def initialize(
      host: Whatsapp.configuration.host,
      version: Whatsapp.configuration.version,
      api_key: Whatsapp.configuration.api_key,
      timeout: nil,
      logger: nil
    )
      @host = host
      @version = version
      @api_key = api_key
      @logger = logger
      @timeout = timeout
    end

    # Sets up and returns the HTTP client with instrumentation and timeout.
    # @return [HTTP::Client] The configured HTTP client
    def connection
      @connection ||= begin
        http = HTTP.persistent(URI.join(@host, @version).to_s)
        http = http.use(instrumentation: { instrumenter: Instrumentation.new(@logger) }) if @logger
        http = http.timeout(@timeout) if @timeout

        http
    end
  end
end
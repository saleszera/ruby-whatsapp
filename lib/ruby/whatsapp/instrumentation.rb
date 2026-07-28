# frozen_string_literal: true

module Whatsapp
  # Instrumentation for logging HTTP requests and responses.
  class Instrumentation
    # @param logger [Logger] The logger instance to use for logging.
    def initialize(logger)
      @logger = logger
    end

    # @param name [String] The name of the event.
    # @param payload [Hash] - optional - The payload containing event data.
    def instrument(name, payload = {})
      error = payload[:error]
      return unless error

      @logger.error("#{name}: #{error.message}")
    end

    # @param payload [Hash] The payload containing event data.
    def start(_, payload)
      request = payload[:request]
      uri = request.uri
      # Log without the query string so identifiers/secrets in params are not logged.
      @logger.info("#{request.verb.to_s.upcase} #{uri.scheme}://#{uri.host}#{uri.path}")
    end

    # @param payload [Hash] The payload containing event data.
    def finish(_, payload)
      response = payload[:response]
      @logger.info("#{response.status.code} #{response.status.reason}")
    end
  end
end

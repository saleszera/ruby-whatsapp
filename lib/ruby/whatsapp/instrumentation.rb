# frozen_string_literal: true

module ChatKit
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
      @logger.info("#{request.verb.upcase} #{request.uri}")
    end

    # @param payload [Hash] The payload containing event data.
    def finish(_, payload)
      response = payload[:response]
      @logger.info("#{response.status.code} #{response.status.reason}")
    end
  end
end
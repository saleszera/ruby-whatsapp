# frozen_string_literal: true

require "logger"
require "uri"
require "http"
require "zeitwerk"
require "active_model"

loader = Zeitwerk::Loader.for_gem
loader.collapse(__dir__)
loader.setup

module Whatsapp
  class Error < StandardError; end

  class << self
    attr_writer :configuration

    # Returns the global configuration, lazily initializing it on first use.
    # @return [Whatsapp::Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the configuration for mutation and returns it.
    # @yieldparam configuration [Whatsapp::Configuration]
    # @return [Whatsapp::Configuration]
    def configure
      yield(configuration) if block_given?

      configuration
    end
  end
end

# Exposed so the whole constant tree can be eagerly loaded (used in tests to
# guarantee every file resolves under Zeitwerk).
Whatsapp.define_singleton_method(:eager_load!) { loader.eager_load }

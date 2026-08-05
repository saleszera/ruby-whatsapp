# frozen_string_literal: true

require "json"
require "logger"
require "uri"
require "http"
require "zeitwerk"
require "active_model"
require "active_support/security_utils"
require "openssl"
require "fileutils"

loader = Zeitwerk::Loader.for_gem
loader.collapse(__dir__)
# The Railtie must be required eagerly (below), not autoloaded, so it's excluded here.
loader.ignore("#{__dir__}/whatsapp/railtie.rb")
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

# Rails discovers Railtie subclasses at boot by class definition, so this must be
# required eagerly (never autoloaded) — and only when Rails is actually present,
# since this gem has no Rails dependency of its own.
require_relative "whatsapp/railtie" if defined?(Rails::Railtie)

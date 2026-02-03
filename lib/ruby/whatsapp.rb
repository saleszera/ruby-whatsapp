# frozen_string_literal: true

require "logger"
require "uri"
require "http"
require "event_stream_parser"
require "zeitwerk"
require "active_model/validations"

loader = Zeitwerk::Loader.for_gem
loader.enable_reloading
loader.setup

module Ruby
  module Whatsapp
    class Error < StandardError; end
    # Your code goes here...

    class << self
      attr_accessor :configuration

      def configure
        self.configuration ||= Whatsapp::Configuration.new

        yield(configuration) if block_given?
      end
  end
end

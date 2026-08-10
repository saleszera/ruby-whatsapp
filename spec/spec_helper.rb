# frozen_string_literal: true

# Coverage must start before the gem is required, or the lines loaded during
# `require "ruby/whatsapp"` below are never tracked. Set COVERAGE=false to skip.
unless ENV["COVERAGE"] == "false"
  require "simplecov"

  SimpleCov.start do
    enable_coverage :branch

    add_filter %r{^/spec/}
    add_filter %r{^/bin/}

    # Zeitwerk loads lazily, so a file no spec touches would otherwise be absent
    # from the report entirely rather than showing as 0%.
    track_files "lib/**/*.rb"

    add_group "Message Templates", "lib/ruby/whatsapp/message_templates"
    add_group "Messages", "lib/ruby/whatsapp/messages"
    add_group "Webhook", "lib/ruby/whatsapp/webhook"
    add_group "Media", "lib/ruby/whatsapp/media.rb"
    add_group "Core", %w[
      lib/ruby/whatsapp/client.rb
      lib/ruby/whatsapp/configuration.rb
      lib/ruby/whatsapp/instrumentation.rb
      lib/ruby/whatsapp/response_handling.rb
    ]

    # Floors, not targets — set below the measured 96.07% line / 85.92% branch so
    # `rake` fails on a real regression rather than on ordinary churn.
    minimum_coverage line: 95, branch: 85
  end
end

require "ruby/whatsapp"
require "faker"
require "webmock/rspec"

# Block all real network access; every HTTP interaction must be stubbed.
WebMock.disable_net_connect!

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Give every example a fresh, populated configuration so global state does
  # not leak between examples and Client picks up test credentials.
  config.before do
    Whatsapp.configuration = Whatsapp::Configuration.new(
      api_key: "TEST_TOKEN",
      phone_id: "PHONE_ID",
      waba_id: "WABA_ID"
    )
  end
end

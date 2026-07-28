# frozen_string_literal: true

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
      phone_id: "PHONE_ID"
    )
  end
end

# frozen_string_literal: true

module Whatsapp
  module Webhook
    # Copies a personalizable webhook controller into a host Rails app. Plain
    # Ruby with no Rails dependency of its own, so it can be unit tested against
    # a plain directory — `lib/tasks/whatsapp.rake` is the thin Rails-facing
    # wrapper around this.
    class Installer
      TEMPLATE_PATH = File.expand_path("templates/webhooks_controller.rb.tt", __dir__)
      DESTINATION = "app/controllers/whatsapp/webhooks_controller.rb"

      NEXT_STEPS = <<~TEXT
        Next steps:

        1. Add these routes to config/routes.rb:

             get  "/whatsapp/webhooks", to: "whatsapp/webhooks#verify"
             post "/whatsapp/webhooks", to: "whatsapp/webhooks#receive"

        2. Configure your verify token and app secret, e.g. in config/initializers/whatsapp.rb:

             Whatsapp.configure do |config|
               config.verify_token = Rails.application.credentials.whatsapp_verify_token
               config.app_secret    = Rails.application.credentials.whatsapp_app_secret
             end

        3. Personalize app/controllers/whatsapp/webhooks_controller.rb — it's your file now.
      TEXT

      class << self
        # @param root [String] The host app's root directory.
        # @param output [IO] Where to print progress and next steps.
        # @return [Symbol] `:created` or `:skipped` (an existing controller is never overwritten).
        def call(root: Dir.pwd, output: $stdout)
          destination = File.join(root, DESTINATION)
          result = write_controller(destination, output)

          output.puts
          output.puts NEXT_STEPS

          result
        end

      private

        def write_controller(destination, output)
          if File.exist?(destination)
            output.puts "Skipped: #{DESTINATION} already exists."
            return :skipped
          end

          FileUtils.mkdir_p(File.dirname(destination))
          FileUtils.cp(TEMPLATE_PATH, destination)
          output.puts "Created #{DESTINATION}"
          :created
        end
      end
    end
  end
end

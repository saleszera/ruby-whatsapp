# frozen_string_literal: true

module Whatsapp
  # Registers `rake whatsapp:install:webhook` with the host Rails app. Only
  # defined when Rails is already loaded — this gem has no Rails dependency of
  # its own. Deliberately excluded from Zeitwerk (see `lib/ruby/whatsapp.rb`)
  # and required eagerly instead: Rails discovers Railtie subclasses at boot by
  # class definition, so autoloading it lazily would be too late.
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path("../../tasks/whatsapp.rake", __dir__)
    end
  end
end

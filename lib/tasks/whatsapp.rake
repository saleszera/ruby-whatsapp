# frozen_string_literal: true

namespace :whatsapp do
  namespace :install do
    desc "Install a personalizable WhatsApp webhook controller into this Rails app"
    task webhook: :environment do
      Whatsapp::Webhook::Installer.call(root: Rails.root)
    end
  end
end

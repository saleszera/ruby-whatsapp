# frozen_string_literal: true

require "tmpdir"

RSpec.describe Whatsapp::Webhook::Installer do
  let(:root) { Dir.mktmpdir }
  let(:output) { StringIO.new }
  let(:destination) { File.join(root, "app/controllers/whatsapp/webhooks_controller.rb") }

  after { FileUtils.remove_entry(root) }

  describe ".call" do
    it "copies the controller template into app/controllers/whatsapp" do
      result = described_class.call(root:, output:)

      expect(result).to eq(:created)
      expect(File.read(destination)).to include("class WebhooksController")
      expect(File.read(destination)).to include("def verify")
      expect(File.read(destination)).to include("def receive")
    end

    it "prints the routes and configuration next steps" do
      described_class.call(root:, output:)

      expect(output.string).to include("config/routes.rb")
      expect(output.string).to include("whatsapp/webhooks#verify")
      expect(output.string).to include("Whatsapp.configure")
    end

    it "does not overwrite an already-customized controller" do
      FileUtils.mkdir_p(File.dirname(destination))
      File.write(destination, "# customized by the developer")

      result = described_class.call(root:, output:)

      expect(result).to eq(:skipped)
      expect(File.read(destination)).to eq("# customized by the developer")
    end
  end
end

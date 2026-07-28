# frozen_string_literal: true

require "rake"

RSpec.describe "lib/tasks/whatsapp.rake" do # rubocop:disable RSpec/DescribeClass
  let(:rake_file) { File.expand_path("../../lib/tasks/whatsapp.rake", __dir__) }

  around do |example|
    original_application = Rake.application
    Rake.application = Rake::Application.new
    example.run
    Rake.application = original_application
  end

  it "defines the whatsapp:install:webhook task without requiring Rails to be loaded" do
    load rake_file

    expect(Rake::Task.task_defined?("whatsapp:install:webhook")).to be(true)
  end
end

# frozen_string_literal: true

RSpec.describe "Whatsapp::Railtie" do
  it "subclasses Rails::Railtie and registers the whatsapp rake tasks, when Rails is present" do
    stub_const("Rails::Railtie", Class.new do
      class << self
        def rake_tasks(&block)
          @rake_tasks_block = block
        end
      end
    end)

    load File.expand_path("../../../lib/ruby/whatsapp/railtie.rb", __dir__)

    expect(Whatsapp::Railtie.ancestors).to include(Rails::Railtie)
    expect(Whatsapp::Railtie.instance_variable_get(:@rake_tasks_block)).to be_a(Proc)
  end
end

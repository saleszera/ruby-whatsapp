# frozen_string_literal: true

RSpec.describe Whatsapp do
  it "has a version number" do
    expect(Whatsapp::VERSION).not_to be_nil
  end
end

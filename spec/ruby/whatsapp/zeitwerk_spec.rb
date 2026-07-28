# frozen_string_literal: true

RSpec.describe "Zeitwerk eager loading" do # rubocop:disable RSpec/DescribeClass
  it "loads every constant in the gem without error" do
    expect { Whatsapp.eager_load! }.not_to raise_error
  end
end

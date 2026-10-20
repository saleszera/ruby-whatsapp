# frozen_string_literal: true

RSpec.describe Whatsapp::Schedule::Statuses do
  it "lists every documented status" do
    expect(described_class::ALL).to eq(%w[COMPLETED FAILED SCHEDULED SENDING])
  end

  it "freezes the list so a caller cannot mutate it" do
    expect(described_class::ALL).to be_frozen
  end
end

# frozen_string_literal: true

RSpec.describe Whatsapp::Messages::Contacts::Org do
  describe "#initialize" do
    context "with no fields" do
      it "is valid" do
        expect { described_class.new }.not_to raise_error
      end
    end

    context "with all fields" do
      it "is valid" do
        expect do
          described_class.new(
            company: Faker::Company.name,
            department: Faker::Commerce.department,
            title: Faker::Job.title
          )
        end.not_to raise_error
      end
    end
  end

  describe "#serialize" do
    context "with no fields" do
      it "returns an empty hash" do
        expect(described_class.new.serialize).to eq({})
      end
    end

    context "with all fields" do
      subject(:serialized) { described_class.new(company:, department:, title:).serialize }

      let(:company) { Faker::Company.name }
      let(:department) { Faker::Commerce.department }
      let(:title) { Faker::Job.title }

      it "includes all fields" do
        expect(serialized[:company]).to eq(company)
        expect(serialized[:department]).to eq(department)
        expect(serialized[:title]).to eq(title)
      end
    end

    context "with only some fields" do
      subject(:serialized) { described_class.new(company: Faker::Company.name).serialize }

      it "omits nil fields" do
        expect(serialized).not_to have_key(:department)
        expect(serialized).not_to have_key(:title)
      end
    end
  end
end

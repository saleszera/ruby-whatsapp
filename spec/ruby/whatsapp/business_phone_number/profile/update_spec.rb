# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Profile::Update do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/whatsapp_business_profile" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "#serialize" do
    it "always sends messaging_product alongside the changed field" do
      expect(described_class.new(about: "Open daily").serialize)
        .to eq({ messaging_product: "whatsapp", about: "Open daily" })
    end

    it "sends every field when all are given" do
      result = described_class.new(
        about: "Open daily", address: "1 Infinite Loop", description: "We sell widgets.",
        email: "hello@acme.test", vertical: "RETAIL", websites: ["https://acme.test"],
        profile_picture_handle: "4::aW1h"
      ).serialize

      expect(result).to eq({
        messaging_product: "whatsapp", about: "Open daily", address: "1 Infinite Loop",
        description: "We sell widgets.", email: "hello@acme.test", vertical: "RETAIL",
        websites: ["https://acme.test"], profile_picture_handle: "4::aW1h",
      })
    end

    it "compacts away every omitted field rather than sending null" do
      expect(described_class.new(email: "hello@acme.test").serialize.keys)
        .to eq(%i[messaging_product email])
    end

    it "normalizes a lowercase or symbol vertical to uppercase" do
      expect(described_class.new(vertical: "retail").serialize[:vertical]).to eq("RETAIL")
      expect(described_class.new(vertical: :prof_services).serialize[:vertical]).to eq("PROF_SERVICES")
    end

    it "sends an empty websites array through, since that is how Meta clears the list" do
      expect(described_class.new(websites: []).serialize).to eq({ messaging_product: "whatsapp", websites: [] })
    end
  end

  describe "validation" do
    it "requires at least one attribute" do
      expect { described_class.new }
        .to raise_error(ActiveModel::ValidationError, /at least one of about, address, description/)
    end

    it "accepts an empty websites array as a deliberate clear" do
      expect { described_class.new(websites: []) }.not_to raise_error
    end

    it "rejects an unsupported vertical" do
      expect { described_class.new(vertical: "SPACESHIPS") }
        .to raise_error(ActiveModel::ValidationError, /Vertical is not included in the list/)
    end

    it "accepts every documented vertical" do
      Whatsapp::BusinessPhoneNumber::Profile::Verticals::ALL.each do |vertical|
        expect { described_class.new(vertical:) }.not_to raise_error
      end
    end

    it "rejects an about longer than 139 characters" do
      expect { described_class.new(about: "a" * 140) }
        .to raise_error(ActiveModel::ValidationError, /About is too long/)
    end

    it "accepts an about of exactly 139 characters" do
      expect { described_class.new(about: "a" * 139) }.not_to raise_error
    end

    it "rejects an address longer than 256 characters" do
      expect { described_class.new(address: "a" * 257) }
        .to raise_error(ActiveModel::ValidationError, /Address is too long/)
    end

    it "accepts an address of exactly 256 characters" do
      expect { described_class.new(address: "a" * 256) }.not_to raise_error
    end

    it "rejects a description longer than 512 characters" do
      expect { described_class.new(description: "a" * 513) }
        .to raise_error(ActiveModel::ValidationError, /Description is too long/)
    end

    it "accepts a description of exactly 512 characters" do
      expect { described_class.new(description: "a" * 512) }.not_to raise_error
    end

    it "rejects an email longer than 128 characters" do
      expect { described_class.new(email: "#{'a' * 120}@acme.test") }
        .to raise_error(ActiveModel::ValidationError, /Email is too long/)
    end

    it "accepts an email of exactly 128 characters" do
      expect { described_class.new(email: "#{'a' * 118}@acme.test") }.not_to raise_error
    end

    it "rejects more than two websites" do
      expect { described_class.new(websites: %w[https://a.test https://b.test https://c.test]) }
        .to raise_error(ActiveModel::ValidationError, /websites accepts at most 2 URLs/)
    end

    it "accepts exactly two websites" do
      expect { described_class.new(websites: %w[https://a.test https://b.test]) }.not_to raise_error
    end

    it "rejects a blank profile_picture_handle" do
      expect { described_class.new(profile_picture_handle: "") }
        .to raise_error(ActiveModel::ValidationError, /Profile picture handle can't be blank/)
    end

    it "does not validate the email's format, which Meta checks server-side" do
      expect { described_class.new(email: "not-an-email") }.not_to raise_error
    end
  end

  describe ".call" do
    it "posts to the phone number's profile edge and returns a response" do
      stub = stub_request(:post, edge)
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" },
          body: { messaging_product: "whatsapp", about: "Open daily" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      result = described_class.call(about: "Open daily")

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Response)
      expect(result.success).to be(true)
      expect(stub).to have_been_requested
    end

    it "posts every field when all are given" do
      stub = stub_request(:post, edge)
        .with(body: {
          messaging_product: "whatsapp", about: "Open daily", address: "1 Infinite Loop",
          description: "We sell widgets.", email: "hello@acme.test", vertical: "RETAIL",
          websites: ["https://acme.test"], profile_picture_handle: "4::aW1h",
        })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(
        about: "Open daily", address: "1 Infinite Loop", description: "We sell widgets.",
        email: "hello@acme.test", vertical: "retail", websites: ["https://acme.test"],
        profile_picture_handle: "4::aW1h"
      )

      expect(stub).to have_been_requested
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER/whatsapp_business_profile")
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      described_class.call(about: "Open daily", client:)

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(about: "Open daily", client:) }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id/)
    end

    it "raises a BusinessPhoneNumber::Error when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 400, headers: json,
        body: { error: { message: "Invalid parameter: email must be a valid email address", code: 100 } }.to_json
      )

      expect { described_class.call(email: "nope") }
        .to raise_error(
          Whatsapp::BusinessPhoneNumber::Error,
          /Failed to update business profile.*must be a valid email address/
        )
    end

    it "reports an unsuccessful update" do
      stub_request(:post, edge).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(described_class.call(about: "Open daily").success).to be(false)
    end

    it "parses a response served as text/javascript" do
      js = { "Content-Type" => "text/javascript; charset=UTF-8" }
      stub_request(:post, edge).to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(described_class.call(about: "Open daily").success).to be(true)
    end

    it "raises a validation error before making any request when no attribute is given" do
      expect { described_class.call }.to raise_error(ActiveModel::ValidationError)
      expect(a_request(:post, edge)).not_to have_been_made
    end

    it "raises a validation error before making any request for an unsupported vertical" do
      expect { described_class.call(vertical: "SPACESHIPS") }.to raise_error(ActiveModel::ValidationError)
      expect(a_request(:post, edge)).not_to have_been_made
    end
  end
end

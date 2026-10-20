# frozen_string_literal: true

RSpec.describe Whatsapp::BusinessPhoneNumber::Username::Claim do
  let(:edge) { "https://graph.facebook.com/v24.0/PHONE_ID/username" }
  let(:json) { { "Content-Type" => "application/json" } }

  describe "TransferActions" do
    it "lists both documented values, in Meta's own lowercase" do
      expect(described_class::TransferActions::ALL).to eq(%w[none force_transfer])
    end

    it "freezes the list so a caller cannot mutate it" do
      expect(described_class::TransferActions::ALL).to be_frozen
    end
  end

  describe "#serialize" do
    it "always sends transfer_action, even at its default" do
      expect(described_class.new(username: "jaspersmarket").serialize)
        .to eq(username: "jaspersmarket", transfer_action: "none")
    end

    it "carries a requested transfer through" do
      expect(described_class.new(username: "jaspersmarket", transfer_action: :force_transfer).serialize)
        .to eq(username: "jaspersmarket", transfer_action: "force_transfer")
    end

    # Meta compares usernames case-insensitively, so downcasing is never worse on the wire
    # and avoids rejecting a name Meta would have accepted.
    it "downcases the username rather than rejecting mixed case" do
      expect(described_class.new(username: "JaspersMarket").serialize[:username]).to eq("jaspersmarket")
    end

    it "accepts either casing for transfer_action" do
      expect(described_class.new(username: "jaspersmarket", transfer_action: "FORCE_TRANSFER").serialize)
        .to eq(username: "jaspersmarket", transfer_action: "force_transfer")
    end
  end

  describe "validation" do
    def claim(username, **options)
      described_class.new(username:, **options)
    end

    it "requires a username" do
      expect { claim(nil) }.to raise_error(ActiveModel::ValidationError, /Username can't be blank/)
      expect { claim("") }.to raise_error(ActiveModel::ValidationError, /Username can't be blank/)
    end

    it "enforces the 3 character minimum" do
      expect { claim("ab") }.to raise_error(ActiveModel::ValidationError, /Username is too short/)
      expect { claim("abc") }.not_to raise_error
    end

    it "enforces the 35 character maximum" do
      expect { claim("a" * 36) }.to raise_error(ActiveModel::ValidationError, /Username is too long/)
      expect { claim("a" * 35) }.not_to raise_error
    end

    it "requires at least one letter" do
      expect { claim("12345") }
        .to raise_error(ActiveModel::ValidationError, /must contain at least one letter/)
      expect { claim("a1234") }.not_to raise_error
    end

    it "rejects characters outside a-z, 0-9, period and underscore" do
      expect { claim("jaspers-market") }
        .to raise_error(ActiveModel::ValidationError, /may only contain a-z, 0-9, periods and underscores/)
      expect { claim("jaspers market") }
        .to raise_error(ActiveModel::ValidationError, /may only contain a-z, 0-9, periods and underscores/)
      expect { claim("jaspers.market_1") }.not_to raise_error
    end

    it "rejects non-English characters" do
      expect { claim("jasperś") }
        .to raise_error(ActiveModel::ValidationError, /may only contain a-z, 0-9, periods and underscores/)
    end

    it "rejects a leading or trailing period" do
      expect { claim(".jaspers") }
        .to raise_error(ActiveModel::ValidationError, /must not start or end with a period/)
      expect { claim("jaspers.") }
        .to raise_error(ActiveModel::ValidationError, /must not start or end with a period/)
    end

    it "rejects two consecutive periods" do
      expect { claim("jaspers..market") }
        .to raise_error(ActiveModel::ValidationError, /must not contain two consecutive periods/)
    end

    # Meta writes the rule as a bare "www" prefix, so this rejects `wwwidgets` too. Pinned
    # deliberately: a local false rejection is reversible, a wasted rate-limited request is not.
    it "rejects a www prefix, read literally" do
      expect { claim("www.jaspers") }
        .to raise_error(ActiveModel::ValidationError, /must not start with www/)
      expect { claim("wwwidgets") }
        .to raise_error(ActiveModel::ValidationError, /must not start with www/)
    end

    it "rejects a domain-like ending from Meta's published list" do
      expect { claim("jaspers.com") }
        .to raise_error(ActiveModel::ValidationError, /must not end with a domain suffix such as \.com/)
      expect { claim("jaspers.html") }
        .to raise_error(ActiveModel::ValidationError, /must not end with a domain suffix such as \.html/)
    end

    # Meta's list ends in "and so on", so a suffix outside it can only be caught server-side.
    it "lets a domain-like ending Meta does not list through to the API" do
      expect { claim("jaspers.shop") }.not_to raise_error
    end

    it "rejects an unsupported transfer_action" do
      expect { claim("jaspersmarket", transfer_action: "steal") }
        .to raise_error(ActiveModel::ValidationError, /Transfer action is not included in the list/)
    end
  end

  describe ".call" do
    it "posts the claim and returns the resulting status" do
      stub = stub_request(:post, edge)
        .with(
          headers: { "Authorization" => "Bearer TEST_TOKEN" },
          body: { username: "jaspersmarket", transfer_action: "none" }.to_json
        )
        .to_return(status: 200, headers: json, body: { status: "approved" }.to_json)

      result = described_class.call(username: "jaspersmarket")

      expect(result).to be_a(Whatsapp::BusinessPhoneNumber::Username::Details)
      expect(result).to be_approved
      expect(result.username).to be_nil
      expect(stub).to have_been_requested
    end

    it "reports a reserved claim, which is not yet visible to WhatsApp users" do
      stub_request(:post, edge).to_return(status: 200, headers: json, body: { status: "reserved" }.to_json)

      expect(described_class.call(username: "jaspersmarket")).to be_reserved
    end

    it "sends a forced transfer when asked" do
      stub = stub_request(:post, edge)
        .with(body: { username: "jaspersmarket", transfer_action: "force_transfer" }.to_json)
        .to_return(status: 200, headers: json, body: { status: "approved" }.to_json)

      described_class.call(username: "jaspersmarket", transfer_action: :force_transfer)

      expect(stub).to have_been_requested
    end

    it "addresses an explicitly passed client's phone number" do
      client = Whatsapp::Client.new(phone_id: "OTHER")
      stub = stub_request(:post, "https://graph.facebook.com/v24.0/OTHER/username")
        .to_return(status: 200, headers: json, body: { status: "approved" }.to_json)

      described_class.call(client:, username: "jaspersmarket")

      expect(stub).to have_been_requested
    end

    it "raises when no phone_id is configured, without making a request" do
      client = Whatsapp::Client.new(phone_id: nil)

      expect { described_class.call(client:, username: "jaspersmarket") }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /phone_id is required for the username edge/)
      expect(a_request(:post, edge)).not_to have_been_made
    end

    it "surfaces the transfer-required error, whose remedy is force_transfer" do
      stub_request(:post, edge).to_return(status: 400, headers: json, body: {
        error: { message: "Username transfer required", code: 147_005 },
      }.to_json)

      expect { described_class.call(username: "jaspersmarket") }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /Username transfer required/)
    end

    it "surfaces the username-unavailable error" do
      stub_request(:post, edge).to_return(status: 400, headers: json, body: {
        error: { message: "Username not available", code: 147_001 },
      }.to_json)

      expect { described_class.call(username: "jaspersmarket") }
        .to raise_error(Whatsapp::BusinessPhoneNumber::Error, /Failed to claim business username/)
    end

    it "validates before spending a request" do
      expect { described_class.call(username: "www.jaspers") }.to raise_error(ActiveModel::ValidationError)
      expect(a_request(:post, edge)).not_to have_been_made
    end
  end
end

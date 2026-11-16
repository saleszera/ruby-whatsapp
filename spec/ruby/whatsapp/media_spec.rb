# frozen_string_literal: true

require "tempfile"
require "tmpdir"

RSpec.describe Whatsapp::Media do
  subject(:media) { described_class.new(client: Whatsapp::Client.new) }

  # The Graph API labels its JSON `text/javascript`, which the http gem cannot
  # infer a parser for. Every read path must name the format explicitly.
  describe "response content type" do
    let(:js) { { "Content-Type" => "text/javascript; charset=UTF-8" } }

    it "parses a media URL response served as text/javascript" do
      stub_request(:get, "https://graph.facebook.com/v24.0/MEDIA_ID").with(query: { phone_number_id: "PHONE_ID" })
        .to_return(status: 200, headers: js, body: { url: "https://lookaside.fbsbx.com/x" }.to_json)

      expect(media.get_url(media_id: "MEDIA_ID")["url"]).to eq("https://lookaside.fbsbx.com/x")
    end

    it "parses a delete response served as text/javascript" do
      stub_request(:delete, "https://graph.facebook.com/v24.0/MEDIA_ID").with(query: { phone_number_id: "PHONE_ID" })
        .to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(media.delete(media_id: "MEDIA_ID")).to be(true)
    end
  end

  describe "#upload" do
    it "posts the file to the versioned media endpoint and returns the media id" do
      file = Tempfile.new(["pic", ".jpg"])
      file.write("data")
      file.close

      stub = stub_request(:post, "https://graph.facebook.com/v24.0/PHONE_ID/media")
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, body: { id: "MEDIA_ID" }.to_json, headers: { "Content-Type" => "application/json" })

      expect(media.upload(file_path: file.path, type: "image/jpeg")).to eq("MEDIA_ID")
      expect(stub).to have_been_requested
    ensure
      file&.unlink
    end

    it "refuses to upload without a phone_id instead of posting to a malformed path" do
      unconfigured = described_class.new(client: Whatsapp::Client.new(phone_id: nil))

      expect { unconfigured.upload(file_path: __FILE__, type: "text/plain") }
        .to raise_error(Whatsapp::Media::MediaError, /phone_id is required for media upload/)
    end

    it "raises when the file does not exist" do
      expect { media.upload(file_path: "/no/such/file.jpg", type: "image/jpeg") }
        .to raise_error(Whatsapp::Media::MediaError, /File not found/)
    end
  end

  describe "#get_url" do
    it "requests the media id endpoint and returns the parsed body" do
      stub_request(:get, "https://graph.facebook.com/v24.0/MEDIA_ID").with(query: { phone_number_id: "PHONE_ID" })
        .with(query: { phone_number_id: "PHONE_ID" })
        .to_return(status: 200, body: { url: "https://lookaside.fbsbx.com/m/1" }.to_json,
          headers: { "Content-Type" => "application/json" })

      expect(media.get_url(media_id: "MEDIA_ID")).to include("url" => "https://lookaside.fbsbx.com/m/1")
    end
  end

  # `phone_number_id` is optional on retrieve and delete; when given, Meta only
  # processes the request if it matches the number the media was uploaded on.
  # See https://developers.facebook.com/documentation/business-messaging/whatsapp/business-phone-numbers/media
  describe "without a configured phone_id" do
    subject(:media) { described_class.new(client: Whatsapp::Client.new(phone_id: nil)) }

    it "retrieves the media URL without a phone_number_id query parameter" do
      stub = stub_request(:get, "https://graph.facebook.com/v24.0/MEDIA_ID")
        .to_return(status: 200, body: { url: "https://lookaside.fbsbx.com/m/1" }.to_json,
          headers: { "Content-Type" => "application/json" })

      media.get_url(media_id: "MEDIA_ID")

      expect(stub).to have_been_requested
    end

    it "deletes the media without a phone_number_id query parameter" do
      stub = stub_request(:delete, "https://graph.facebook.com/v24.0/MEDIA_ID")
        .to_return(status: 200, body: { success: true }.to_json, headers: { "Content-Type" => "application/json" })

      expect(media.delete(media_id: "MEDIA_ID")).to be(true)
      expect(stub).to have_been_requested
    end
  end

  describe "#delete" do
    it "returns true when the API reports success" do
      stub_request(:delete, "https://graph.facebook.com/v24.0/MEDIA_ID").with(query: { phone_number_id: "PHONE_ID" })
        .with(query: { phone_number_id: "PHONE_ID" })
        .to_return(status: 200, body: { success: true }.to_json, headers: { "Content-Type" => "application/json" })

      expect(media.delete(media_id: "MEDIA_ID")).to be(true)
    end
  end

  describe "#download" do
    let(:save_to) { File.join(Dir.mktmpdir, "out.bin") }

    it "downloads from an allowlisted host with the bearer token and writes the file" do
      stub_request(:get, "https://lookaside.fbsbx.com/media/abc")
        .with(headers: { "Authorization" => "Bearer TEST_TOKEN" })
        .to_return(status: 200, body: "BINARYDATA")

      media.download(url: "https://lookaside.fbsbx.com/media/abc", save_to:)

      expect(File.binread(save_to)).to eq("BINARYDATA")
    end

    it "refuses a non-allowlisted host and never sends the token" do
      expect { media.download(url: "https://evil.com/steal", save_to:) }
        .to raise_error(Whatsapp::Media::MediaError, /non-allowlisted host/)

      expect(a_request(:get, "https://evil.com/steal")).not_to have_been_made
    end

    it "refuses a non-HTTPS URL" do
      expect { media.download(url: "http://lookaside.fbsbx.com/x", save_to:) }
        .to raise_error(Whatsapp::Media::MediaError, /non-HTTPS/)
    end
  end
end

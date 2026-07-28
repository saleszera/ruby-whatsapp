# frozen_string_literal: true

require "tempfile"
require "tmpdir"

RSpec.describe Whatsapp::Media do
  subject(:media) { described_class.new(client: Whatsapp::Client.new) }

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

    it "raises when the file does not exist" do
      expect { media.upload(file_path: "/no/such/file.jpg", type: "image/jpeg") }
        .to raise_error(Whatsapp::Media::MediaError, /File not found/)
    end
  end

  describe "#get_url" do
    it "requests the media id endpoint and returns the parsed body" do
      stub_request(:get, "https://graph.facebook.com/v24.0/MEDIA_ID")
        .with(query: { phone_number_id: "PHONE_ID" })
        .to_return(status: 200, body: { url: "https://lookaside.fbsbx.com/m/1" }.to_json,
          headers: { "Content-Type" => "application/json" })

      expect(media.get_url(media_id: "MEDIA_ID")).to include("url" => "https://lookaside.fbsbx.com/m/1")
    end
  end

  describe "#delete" do
    it "returns true when the API reports success" do
      stub_request(:delete, "https://graph.facebook.com/v24.0/MEDIA_ID")
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

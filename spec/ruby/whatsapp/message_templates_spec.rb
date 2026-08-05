# frozen_string_literal: true

RSpec.describe Whatsapp::MessageTemplates do
  subject(:templates) { described_class.new }

  let(:edge) { "https://graph.facebook.com/v24.0/WABA_ID/message_templates" }
  let(:json) { { "Content-Type" => "application/json" } }
  let(:body) { { type: :body, text: "Thank you for your order." } }

  def create_attrs(**overrides)
    {
      name: "order_confirmation", language: "en_US",
      category: Whatsapp::MessageTemplates::Categories::UTILITY, components: [body],
    }.merge(overrides)
  end

  describe "#create" do
    it "posts the serialized template to the WABA edge and returns the created response" do
      stub = stub_request(:post, edge)
        .with(
          headers: { "Authorization" => "Bearer TEST_TOKEN" },
          body: {
            name: "order_confirmation", language: "en_US", category: "UTILITY",
            parameter_format: "POSITIONAL",
            components: [{ type: "BODY", text: "Thank you for your order." }],
          }
        )
        .to_return(status: 200, headers: json,
          body: { id: "1259544702043867", status: "PENDING", category: "UTILITY" }.to_json)

      result = templates.create(**create_attrs)

      expect(result).to be_a(Whatsapp::MessageTemplates::Response::Created)
      expect(result.id).to eq("1259544702043867")
      expect(result).to be_pending
      expect(stub).to have_been_requested
    end

    it "validates before making any request" do
      expect { templates.create(**create_attrs(name: "Bad Name")) }
        .to raise_error(ActiveModel::ValidationError)

      expect(a_request(:post, edge)).not_to have_been_made
    end

    it "raises a TemplateError when the API rejects the request" do
      stub_request(:post, edge).to_return(
        status: 400, headers: json,
        body: { error: { message: "Invalid parameter", code: 100 } }.to_json
      )

      expect { templates.create(**create_attrs) }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /Failed to create template.*Invalid parameter/)
    end

    it "raises when no waba_id is configured" do
      client = Whatsapp::Client.new(waba_id: nil)

      expect { described_class.new(client:).create(**create_attrs) }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /waba_id/)
    end
  end

  describe "#create_from_library" do
    it "posts the library clone payload to the same edge" do
      stub = stub_request(:post, edge)
        .with(body: {
          name: "my_delivery_update", language: "en_US", category: "UTILITY",
          library_template_name: "delivery_update_1",
        })
        .to_return(status: 200, headers: json,
          body: { id: "1", status: "APPROVED", category: "UTILITY" }.to_json)

      result = templates.create_from_library(
        name: "my_delivery_update", language: "en_US", category: "UTILITY",
        library_template_name: "delivery_update_1"
      )

      expect(result).to be_approved
      expect(stub).to have_been_requested
    end
  end

  describe "#upsert" do
    let(:upsert_edge) { "https://graph.facebook.com/v24.0/WABA_ID/upsert_message_templates" }

    it "posts to the upsert edge with a languages array" do
      stub = stub_request(:post, upsert_edge)
        .with(body: hash_including("languages" => %w[en_US es_ES]))
        .to_return(status: 200, headers: json,
          body: { id: "1", status: "APPROVED", category: "AUTHENTICATION" }.to_json)

      result = templates.upsert(
        name: "auth_code", languages: %w[en_US es_ES], category: "AUTHENTICATION",
        components: [
          { type: :body, add_security_recommendation: true },
          { type: :buttons, buttons: [{ type: :otp, otp_type: "COPY_CODE" }] },
        ]
      )

      expect(result.id).to eq("1")
      expect(stub).to have_been_requested
    end

    it "requires languages rather than a single language" do
      expect { templates.upsert(**create_attrs) }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /requires `languages:`/)
    end
  end

  describe "#list" do
    it "gets the WABA edge and returns a collection" do
      stub = stub_request(:get, edge)
        .to_return(status: 200, headers: json, body: {
          data: [{ id: "1", name: "order_confirmation", status: "APPROVED" }],
          paging: { cursors: { after: "AFTER" } },
          summary: { total_count: 1, message_template_count: 1, message_template_limit: 250 },
        }.to_json)

      result = templates.list

      expect(result).to be_a(Whatsapp::MessageTemplates::Response::Collection)
      expect(result.map(&:name)).to eq(%w[order_confirmation])
      expect(result.next_cursor).to eq("AFTER")
      expect(result.remaining).to eq(249)
      expect(stub).to have_been_requested
    end

    it "passes scalar filters through as query parameters" do
      stub = stub_request(:get, edge)
        .with(query: { name: "order_confirmation", limit: "5" })
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      templates.list(name: "order_confirmation", limit: 5)

      expect(stub).to have_been_requested
    end

    it "encodes array filters as JSON arrays, which is what the Graph API expects" do
      stub = stub_request(:get, edge)
        .with(query: { status: '["APPROVED","PAUSED"]', category: '["UTILITY"]' })
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      templates.list(status: %w[APPROVED PAUSED], category: %w[UTILITY])

      expect(stub).to have_been_requested
    end

    it "joins a fields array into a comma separated list" do
      stub = stub_request(:get, edge)
        .with(query: { fields: "name,category,status" })
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      templates.list(fields: %w[name category status])

      expect(stub).to have_been_requested
    end

    it "drops nil filters" do
      stub = stub_request(:get, edge)
        .with(query: { name: "x" })
        .to_return(status: 200, headers: json, body: { data: [] }.to_json)

      templates.list(name: "x", status: nil)

      expect(stub).to have_been_requested
    end

    it "raises a TemplateError when the API rejects the request" do
      stub_request(:get, edge).to_return(status: 403, headers: json,
        body: { error: { message: "Permissions error", code: 200 } }.to_json)

      expect { templates.list }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /Failed to list templates/)
    end
  end

  describe "#find" do
    let(:node_url) { "https://graph.facebook.com/v24.0/564750795574598" }

    it "gets the template node and returns it typed" do
      stub = stub_request(:get, node_url)
        .to_return(status: 200, headers: json, body: {
          id: "564750795574598", name: "order_confirmation", status: "APPROVED", category: "UTILITY",
        }.to_json)

      result = templates.find(template_id: "564750795574598")

      expect(result).to be_a(Whatsapp::MessageTemplates::Response::Node)
      expect(result.name).to eq("order_confirmation")
      expect(result).to be_approved
      expect(stub).to have_been_requested
    end

    it "requests only the given fields" do
      stub = stub_request(:get, node_url)
        .with(query: { fields: "status" })
        .to_return(status: 200, headers: json, body: { id: "564750795574598", status: "APPROVED" }.to_json)

      templates.find(template_id: "564750795574598", fields: %w[status])

      expect(stub).to have_been_requested
    end

    it "requires a template id" do
      expect { templates.find(template_id: nil) }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /template_id can't be blank/)
    end
  end

  describe "#update" do
    let(:node_url) { "https://graph.facebook.com/v24.0/564750795574598" }

    it "posts the category to the template node and returns true" do
      stub = stub_request(:post, node_url)
        .with(body: { category: "MARKETING" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      expect(templates.update(template_id: "564750795574598", category: "MARKETING")).to be(true)
      expect(stub).to have_been_requested
    end

    it "posts replacement components, validated before sending" do
      stub = stub_request(:post, node_url)
        .with(body: {
          components: [
            { type: "HEADER", format: "TEXT", text: "Our {{1}} is on!", example: { header_text: ["Spring Sale"] } },
            { type: "BODY", text: "Shop now through {{1}}.", example: { body_text: [["the end of April"]] } },
          ],
        })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      result = templates.update(
        template_id: "564750795574598",
        components: [
          { type: :header, format: "TEXT", text: "Our {{1}} is on!", example: ["Spring Sale"] },
          { type: :body, text: "Shop now through {{1}}.", example: ["the end of April"] },
        ]
      )

      expect(result).to be(true)
      expect(stub).to have_been_requested
    end

    it "posts the ttl override" do
      stub = stub_request(:post, node_url)
        .with(body: { message_send_ttl_seconds: 3600 })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      templates.update(template_id: "564750795574598", message_send_ttl_seconds: 3600)

      expect(stub).to have_been_requested
    end

    it "applies cross-component rules to the replacement components" do
      expect { templates.update(template_id: "1", components: [{ type: :footer, text: "Bye" }]) }
        .to raise_error(ActiveModel::ValidationError, /requires exactly one BODY/)

      expect(a_request(:post, "https://graph.facebook.com/v24.0/1")).not_to have_been_made
    end

    it "rejects an empty edit" do
      expect { templates.update(template_id: "1") }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /nothing to update/)
    end

    it "returns false when the API does not report success" do
      stub_request(:post, node_url).to_return(status: 200, headers: json, body: { success: false }.to_json)

      expect(templates.update(template_id: "564750795574598", category: "MARKETING")).to be(false)
    end
  end

  describe "#delete" do
    it "deletes every language variant by name" do
      stub = stub_request(:delete, edge)
        .with(query: { name: "order_confirmation" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      expect(templates.delete(name: "order_confirmation")).to be(true)
      expect(stub).to have_been_requested
    end

    it "deletes a single template by id, with its name alongside" do
      stub = stub_request(:delete, edge)
        .with(query: { hsm_id: "1407680676729941", name: "order_confirmation" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      templates.delete(hsm_id: "1407680676729941", name: "order_confirmation")

      expect(stub).to have_been_requested
    end

    it "deletes several templates by id" do
      stub = stub_request(:delete, edge)
        .with(query: { hsm_ids: "[1387372356726668,1304694804498707]" })
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      templates.delete(hsm_ids: %w[1387372356726668 1304694804498707])

      expect(stub).to have_been_requested
    end

    it "requires at least one way to address the template" do
      expect { templates.delete }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /requires name, hsm_id or hsm_ids/)
    end

    it "refuses to combine hsm_ids with name" do
      expect { templates.delete(hsm_ids: %w[1], name: "x") }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /cannot be combined/)
    end

    it "refuses to combine hsm_ids with hsm_id" do
      expect { templates.delete(hsm_ids: %w[1], hsm_id: "2") }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /cannot be combined/)
    end

    it "refuses more than 100 ids in one request" do
      expect { templates.delete(hsm_ids: Array.new(101, &:to_s)) }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /at most 100/)
    end

    it "accepts exactly 100 ids" do
      stub_request(:delete, edge)
        .with(query: hash_including({}))
        .to_return(status: 200, headers: json, body: { success: true }.to_json)

      expect(templates.delete(hsm_ids: Array.new(100, &:to_s))).to be(true)
    end

    it "raises a TemplateError when the API rejects the request" do
      stub_request(:delete, edge)
        .with(query: { name: "x" })
        .to_return(status: 403, headers: json,
          body: { error: { message: "Permissions error", code: 200 } }.to_json)

      expect { templates.delete(name: "x") }
        .to raise_error(Whatsapp::MessageTemplates::TemplateError, /Failed to delete template/)
    end
  end

  describe "response content type" do
    # The Graph API labels its JSON `text/javascript`, which the http gem cannot
    # infer a parser for. Every read path must name the format explicitly.
    let(:js) { { "Content-Type" => "text/javascript; charset=UTF-8" } }

    it "parses a create response served as text/javascript" do
      stub_request(:post, edge)
        .to_return(status: 200, headers: js, body: { id: "1", status: "PENDING" }.to_json)

      expect(templates.create(**create_attrs).id).to eq("1")
    end

    it "parses a list response served as text/javascript" do
      stub_request(:get, edge)
        .to_return(status: 200, headers: js, body: { data: [{ id: "1", name: "a" }] }.to_json)

      expect(templates.list.count).to eq(1)
    end

    it "parses a find response served as text/javascript" do
      stub_request(:get, "https://graph.facebook.com/v24.0/1")
        .to_return(status: 200, headers: js, body: { id: "1", name: "a", status: "APPROVED" }.to_json)

      expect(templates.find(template_id: "1").name).to eq("a")
    end

    it "parses an update response served as text/javascript" do
      stub_request(:post, "https://graph.facebook.com/v24.0/1")
        .to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(templates.update(template_id: "1", components: [body])).to be(true)
    end

    it "parses a delete response served as text/javascript" do
      stub_request(:delete, edge).with(query: { name: "a" })
        .to_return(status: 200, headers: js, body: { success: true }.to_json)

      expect(templates.delete(name: "a")).to be(true)
    end
  end

  describe "client wiring" do
    it "defaults to a client built from the global configuration" do
      expect(templates.client.waba_id).to eq("WABA_ID")
    end

    it "accepts an injected client" do
      client = Whatsapp::Client.new(waba_id: "OTHER")

      expect(described_class.new(client:).client.waba_id).to eq("OTHER")
    end
  end
end

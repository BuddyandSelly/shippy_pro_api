# frozen_string_literal: true

RSpec.describe ShippyProAPI::Client do
  let(:api_key) { "test_key" }
  let(:client) { described_class.new(api_key: api_key) }
  let(:expected_auth_header) { "Basic #{Base64.strict_encode64("#{api_key}:")}" }

  describe "#connection" do
    subject(:conn) { client.connection }

    it "returns a Faraday connection" do
      expect(conn).to be_a(Faraday::Connection)
    end

    it "points at the ShippyPro API base URL" do
      expect(conn.url_prefix.to_s).to start_with("https://www.shippypro.com/api")
    end

    it "sets the HTTP Basic Authorization header from the api_key" do
      expect(conn.headers["Authorization"]).to eq(expected_auth_header)
    end

    it "memoizes the connection across calls" do
      expect(client.connection).to equal(conn)
    end
  end

  describe "shipment.create (round-trip through the middleware stack)" do
    let(:request_body) { { from_address: { name: "ACME" }, to_address: { name: "Buddy" }, foo: "bar" } }
    let(:response_body) do
      {
        "OrderID" => "abc123",
        "LabelURL" => "https://example.com/label.pdf",
        "TrackingNumber" => "TRACK-001",
        "CarrierName" => "DHLeCommercePL"
      }
    end

    before do
      stub_request(:post, "https://www.shippypro.com/api")
        .with(
          headers: {
            "Authorization" => expected_auth_header,
            "Content-Type" => "application/json"
          }
        ) { |req|
          parsed = JSON.parse(req.body)
          expect(parsed["Method"]).to eq("Ship")
          expect(parsed["Params"]).to include("from_address", "to_address", "Foo" => "bar")
          true
        }
        .to_return(
          status: 200,
          body: response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "serializes the request as JSON with the ShippyPro envelope and parses the response" do
      shipment = client.shipment.create(request_body)

      expect(shipment).to be_a(ShippyProAPI::Shipment)
      expect(shipment.order_id).to eq("abc123")
      expect(shipment.label_url).to eq("https://example.com/label.pdf")
      expect(shipment.tracking_number).to eq("TRACK-001")
      expect(shipment.carrier_name).to eq("DHLeCommercePL")
    end
  end

  describe "error handling" do
    it "raises ShippyProAPI::Error on 401" do
      stub_request(:post, "https://www.shippypro.com/api")
        .to_return(status: 401, body: '{"Error": "invalid api key"}', headers: { "Content-Type" => "application/json" })

      expect { client.shipment.create({}) }.to raise_error(ShippyProAPI::Error, /Invalid authorization/)
    end

    it "raises ShippyProAPI::Error on 429" do
      stub_request(:post, "https://www.shippypro.com/api")
        .to_return(status: 429, body: '{"Error": "rate limit"}', headers: { "Content-Type" => "application/json" })

      expect { client.shipment.create({}) }.to raise_error(ShippyProAPI::Error, /rate limit/)
    end

    it "raises ShippyProAPI::Error on 500" do
      stub_request(:post, "https://www.shippypro.com/api")
        .to_return(status: 500, body: '{"Error": "boom"}', headers: { "Content-Type" => "application/json" })

      expect { client.shipment.create({}) }.to raise_error(ShippyProAPI::Error, /unhandled error/)
    end
  end
end

# frozen_string_literal: true

RSpec.describe ShippyProAPI::ShipmentResource do
  let(:client) { ShippyProAPI::Client.new(api_key: "test_key") }

  # WebMock passes the request to a dynamic response block, which is the place
  # where the serialized request body can be read back.
  def stub_api(body)
    captured = nil
    stub_request(:post, "https://www.shippypro.com/api").to_return do |request|
      captured = JSON.parse(request.body)
      { status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" } }
    end
    -> { captured }
  end

  describe "#retrieve_rates" do
    it "wraps Rates and RatesErrors in objects" do
      stub_api(
        "Rates" => [
          { "CarrierName" => "DHLParcelPL", "CarrierService" => "Domestic", "Rate" => 12.5 },
          { "CarrierName" => "InPost", "CarrierService" => "Locker", "Rate" => 9.9 }
        ],
        "RatesErrors" => [{ "CarrierName" => "UPS", "Message" => "no contract" }]
      )

      rates = client.shipment.retrieve_rates(to_address: { zip: "00-001" })

      expect(rates.rates.map(&:carrier_name)).to eq(%w[DHLParcelPL InPost])
      expect(rates.rates.first.rate).to eq(12.5)
      expect(rates.rates_errors.map(&:message)).to eq(["no contract"])
    end

    it "sends the GetRates envelope" do
      capture = stub_api("Rates" => [])

      client.shipment.retrieve_rates(carrier_id: 283)

      expect(capture.call).to eq("Method" => "GetRates", "Params" => { "CarrierID" => 283 })
    end

    # ShippyPro omits the keys entirely when it has nothing to say about either.
    it "leaves rates and rates_errors nil when the response carries neither key" do
      stub_api("Warning" => "no carriers configured")

      rates = client.shipment.retrieve_rates({})

      expect(rates.rates).to be_nil
      expect(rates.rates_errors).to be_nil
    end

    it "leaves rates_errors nil when only Rates comes back" do
      stub_api("Rates" => [{ "CarrierName" => "DHLParcelPL", "Rate" => 12.5 }])

      rates = client.shipment.retrieve_rates({})

      expect(rates.rates.first.carrier_name).to eq("DHLParcelPL")
      expect(rates.rates_errors).to be_nil
    end
  end

  describe "#track" do
    it "sends the tracking number as the GetTracking code param" do
      capture = stub_api("Status" => "Delivered")

      client.shipment.track("TRACK-001")

      expect(capture.call).to eq("Method" => "GetTracking", "Params" => { "Code" => "TRACK-001" })
    end

    it "returns the tracking info as an object with underscored readers" do
      stub_api(
        "Status" => "Delivered",
        "TrackingNumber" => "TRACK-001",
        "Events" => [
          { "Date" => "2026-08-30T09:00:00Z", "Status" => "In transit" },
          { "Date" => "2026-08-31T11:20:00Z", "Status" => "Delivered" }
        ]
      )

      info = client.shipment.track("TRACK-001")

      expect(info).to be_a(ShippyProAPI::TrackingInfo)
      expect(info.status).to eq("Delivered")
      expect(info.tracking_number).to eq("TRACK-001")
      expect(info.events.map(&:status)).to eq(["In transit", "Delivered"])
    end

    it "raises on an API error reported in the tracking response" do
      stub_api("Error" => "Tracking code not found")

      expect { client.shipment.track("NOPE") }
        .to raise_error(ShippyProAPI::ApiError, "Tracking code not found")
    end
  end
end

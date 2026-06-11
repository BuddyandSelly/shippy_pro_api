# frozen_string_literal: true

RSpec.describe "API errors reported inside HTTP 200 responses" do
  let(:client) { ShippyProAPI::Client.new(api_key: "test_key") }

  def stub_response(body)
    stub_request(:post, "https://www.shippypro.com/api")
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })
  end

  it "raises ApiError when the body contains an Error field" do
    stub_response("Error" => "CarrierID not found")

    expect { client.shipment.create(carrier_id: 999) }
      .to raise_error(ShippyProAPI::ApiError, "CarrierID not found")
  end

  it "raises ApiError when the body contains an ErrorMessage field" do
    stub_response("ErrorMessage" => "Invalid destination zip")

    expect { client.shipment.create({}) }
      .to raise_error(ShippyProAPI::ApiError, "Invalid destination zip")
  end

  it "attaches the full response body to the error for debugging" do
    stub_response("Error" => "boom", "TransactionID" => "RS1-S2")

    client.shipment.create({})
  rescue ShippyProAPI::ApiError => e
    expect(e.body).to eq("Error" => "boom", "TransactionID" => "RS1-S2")
  end

  it "is a subclass of ShippyProAPI::Error so existing rescues still catch it" do
    expect(ShippyProAPI::ApiError.ancestors).to include(ShippyProAPI::Error)
  end

  it "does not raise on a successful Ship response" do
    stub_response("LabelURL" => ["https://example.com/label.pdf"], "TrackingNumber" => "TRACK-001")

    shipment = client.shipment.create(carrier_id: 283)
    expect(shipment.label_url).to eq(["https://example.com/label.pdf"])
  end

  it "does not raise when GetRates returns a populated RatesErrors array (not a fatal error)" do
    stub_response(
      "Rates" => [{ "CarrierName" => "DHLParcelPL", "Rate" => 12.5 }],
      "RatesErrors" => [{ "CarrierName" => "UPS", "Message" => "no contract" }]
    )

    rates = client.shipment.retrieve_rates({})
    expect(rates.rates.first.carrier_name).to eq("DHLParcelPL")
    expect(rates.rates_errors.first.carrier_name).to eq("UPS")
  end

  it "does not raise when the Error field is present but empty" do
    stub_response("Error" => "", "LabelURL" => ["https://example.com/label.pdf"])

    expect { client.shipment.create({}) }.not_to raise_error
  end
end

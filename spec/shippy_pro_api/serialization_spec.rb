# frozen_string_literal: true

RSpec.describe "request key serialization" do
  let(:client) { ShippyProAPI::Client.new(api_key: "test_key") }

  def stub_ship_and_capture
    captured = nil
    stub_request(:post, "https://www.shippypro.com/api")
      .with { |req| captured = JSON.parse(req.body); true }
      .to_return(
        status: 200,
        body: { "LabelURL" => ["https://example.com/label.pdf"] }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    -> { captured }
  end

  describe "acronym special cases" do
    it "serializes carrier_id as CarrierID and transaction_id as TransactionID" do
      capture = stub_ship_and_capture

      client.shipment.create(carrier_id: 283, transaction_id: "RS1-S2", rate_id: 9, api_orders_id: 7)

      params = capture.call["Params"]
      expect(params).to include("CarrierID" => 283, "TransactionID" => "RS1-S2", "RateID" => 9, "APIOrdersID" => 7)
      expect(params.keys).not_to include("CarrierId", "TransactionId", "RateId", "ApiOrdersId")
    end

    it "leaves keys that are already exactly cased untouched (backward compatibility)" do
      capture = stub_ship_and_capture

      client.shipment.create("CarrierID" => 283, "IsReturn" => true)

      expect(capture.call["Params"]).to include("CarrierID" => 283, "IsReturn" => true)
    end
  end

  describe "snake_case passthrough keys" do
    it "keeps weight_unit and dimension_unit in snake_case" do
      capture = stub_ship_and_capture

      client.shipment.create(weight_unit: "kg", dimension_unit: "cm")

      params = capture.call["Params"]
      expect(params).to include("weight_unit" => "kg", "dimension_unit" => "cm")
      expect(params.keys).not_to include("WeightUnit", "DimensionUnit")
    end
  end

  describe "golden payload" do
    # Mirrors the Postman-verified DHLParcelPL domestic return request, called the way
    # an application would (snake_case keys). Any serialization regression fails here.
    it "produces exactly the ShippyPro Ship payload verified in Postman" do
      capture = stub_ship_and_capture

      client.shipment.create(
        carrier_name: "DHLParcelPL",
        carrier_service: "Domestic Return",
        carrier_id: 283,
        from_address: {
          name: "Jan Kowalski", company: "", street1: "ul. Marszałkowska 45", street2: "",
          city: "Warszawa", state: "", zip: "00-648", country: "PL",
          phone: "+48501122334", email: "jan.kowalski@example.pl"
        },
        to_address: {
          name: "Acme Warehouse", company: "Acme Sp. z o.o.", street1: "ul. Magazynowa 12", street2: "",
          city: "Warszawa", state: "", zip: "00-001", country: "PL",
          phone: "+48221234567", email: "warehouse@acme.pl"
        },
        parcels: [{ length: 30, width: 20, height: 10, weight: 1.5 }],
        weight_unit: "kg",
        dimension_unit: "cm",
        transaction_id: "ORD-2026-000125",
        content_description: "Shoes - size 42",
        total_value: "120.00 EUR",
        insurance: 0,
        insurance_currency: "EUR",
        cash_on_delivery: 0,
        cash_on_delivery_currency: "EUR",
        async: false,
        label_format: "PDF",
        is_return: true
      )

      expect(capture.call).to eq(
        "Method" => "Ship",
        "Params" => {
          "CarrierName" => "DHLParcelPL",
          "CarrierService" => "Domestic Return",
          "CarrierID" => 283,
          "from_address" => {
            "name" => "Jan Kowalski", "company" => "", "street1" => "ul. Marszałkowska 45", "street2" => "",
            "city" => "Warszawa", "state" => "", "zip" => "00-648", "country" => "PL",
            "phone" => "+48501122334", "email" => "jan.kowalski@example.pl"
          },
          "to_address" => {
            "name" => "Acme Warehouse", "company" => "Acme Sp. z o.o.", "street1" => "ul. Magazynowa 12", "street2" => "",
            "city" => "Warszawa", "state" => "", "zip" => "00-001", "country" => "PL",
            "phone" => "+48221234567", "email" => "warehouse@acme.pl"
          },
          "parcels" => [{ "length" => 30, "width" => 20, "height" => 10, "weight" => 1.5 }],
          "weight_unit" => "kg",
          "dimension_unit" => "cm",
          "TransactionID" => "ORD-2026-000125",
          "ContentDescription" => "Shoes - size 42",
          "TotalValue" => "120.00 EUR",
          "Insurance" => 0,
          "InsuranceCurrency" => "EUR",
          "CashOnDelivery" => 0,
          "CashOnDeliveryCurrency" => "EUR",
          "Async" => false,
          "LabelFormat" => "PDF",
          "IsReturn" => true
        }
      )
    end
  end
end

# frozen_string_literal: true

module ShippyProAPI
  # The Ship, GetRates and GetTracking endpoints.
  class ShipmentResource < Resource
    def create(attributes)
      Shipment.new(post_request("Ship", body: attributes).body)
    end

    def retrieve_rates(attributes)
      response = post_request("GetRates", body: attributes).body

      available_rates = response["Rates"]&.map { |rate| Rate.new(rate) }
      rates_errors = response["RatesErrors"]&.map { |rate| RateError.new(rate) }

      Rates.new(rates: available_rates, rates_errors: rates_errors)
    end

    def track(tracking_number)
      attributes = { code: tracking_number }

      TrackingInfo.new(post_request("GetTracking", body: attributes).body)
    end

    private

    def post_request(method, body:)
      attributes = {
        method: method,
        params: body
      }
      super("", body: attributes)
    end
  end
end

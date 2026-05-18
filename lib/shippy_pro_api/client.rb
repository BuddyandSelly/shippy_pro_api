require "faraday"
require "faraday_middleware"

module ShippyProAPI
  class Client
    BASE_URL = "https://www.shippypro.com/api"

    attr_reader :api_key, :adapter, :config

    def initialize(api_key:, adapter: Faraday.default_adapter, config: {})
      @api_key = api_key
      @adapter = adapter
      @config = config
    end

    def connection
      @connection ||=
        Faraday.new(config) do |conn|
          conn.url_prefix = BASE_URL
          conn.headers["Authorization"] = "Basic #{encoded_credentials}"
          conn.request :json
          conn.response :json, content_type: "application/json"
          conn.adapter adapter
        end
    end

    def shipment
      ShipmentResource.new(self)
    end

    private

    def encoded_credentials
      Base64.strict_encode64("#{api_key}:")
    end
  end
end

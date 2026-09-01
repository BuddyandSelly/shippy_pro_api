# frozen_string_literal: true

# The json request and response middleware ships with faraday itself since
# 1.10, so faraday_middleware is not needed for it any more.
require "faraday"
require "base64"

module ShippyProAPI
  # Holds the credentials and builds the Faraday connection every resource posts to.
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

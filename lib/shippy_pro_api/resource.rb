# frozen_string_literal: true

require "active_support/core_ext/string"

module ShippyProAPI
  class Resource
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def post_request(url, body:, headers: {})
      handle_response client.connection.post(url, parse_body(body), headers)
    end

    private

    # Keys ShippyPro expects in snake_case; passed through untouched (including nested content).
    SNAKE_CASE_KEYS = %w[to_address from_address parcels weight_unit dimension_unit].freeze

    # Keys where Rails camelize produces the wrong acronym casing for ShippyPro's API.
    SPECIAL_CASE_KEYS = {
      "carrier_id" => "CarrierID",
      "transaction_id" => "TransactionID",
      "rate_id" => "RateID",
      "api_orders_id" => "APIOrdersID"
    }.freeze

    # ShippyPro can report failures in a 200 response body via these fields.
    API_ERROR_KEYS = %w[Error ErrorMessage].freeze

    def handle_response(response)
      error_message = response.body

      case response.status
      when 400
        raise Error, "A bad request or a validation exception has occurred. #{error_message}"
      when 401
        raise Error, "Invalid authorization credentials. #{error_message}"
      when 403
        raise Error, "Connection doesn't have permission to access the resource. #{error_message}"
      when 404
        raise Error, "The resource you have specified cannot be found. #{error_message}"
      when 429
        raise Error, "The API rate limit for your application has been exceeded. #{error_message}"
      when 500
        raise Error,
              "An unhandled error with the server. Contact the ShippyPro team if problems persist. #{error_message}"
      when 503
        raise Error,
              "API is currently unavailable – typically due to a scheduled outage – try again soon. #{error_message}"
      end

      raise_on_api_error(response)

      response
    end

    def raise_on_api_error(response)
      body = response.body
      return unless body.is_a?(Hash)

      error_key = API_ERROR_KEYS.find { |key| body[key].is_a?(String) && !body[key].empty? }
      return unless error_key

      raise ApiError.new(body[error_key], body)
    end

    def parse_body(params)
      camelize_selected_keys(params)
    end

    # camelcase the param keys except for the SNAKE_CASE_KEYS (and their respective nested keys),
    # using SPECIAL_CASE_KEYS where ShippyPro's acronym casing differs from Rails camelize
    # (e.g. carrier_id must become "CarrierID", not "CarrierId").

    # example
    # {:parcels=>[{:test=>"yes"}], :foo=>"bar", :carrier_id=>283}
    # returns
    # {"parcels"=>[{:test=>"yes"}], "Foo"=>"bar", "CarrierID"=>283}

    def camelize_selected_keys(params)
      if params.is_a?(Hash)
        params.each_with_object({}) do |(key, value), new_hash|
          key = key.to_s
          if SNAKE_CASE_KEYS.include?(key)
            new_hash[key] = value
          else
            new_hash[SPECIAL_CASE_KEYS.fetch(key, key.camelcase)] = camelize_selected_keys(value)
          end
        end
      elsif params.is_a?(Array)
        params.map { |value| camelize_selected_keys(value) }
      else
        params
      end
    end

    def parse_response(response)
      response.body.deep_transform_keys { |key| key.to_s.underscore }
    end
  end
end

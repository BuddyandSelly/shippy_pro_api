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

      response
    end

    def parse_body(params)
      camelize_selected_keys(params)
    end

    # camelcase the param keys except for the to_address, from_address, and parcels keys and their respective nested keys

    # example
    # {:parcels=>[{:test=>"yes"}], :foo=>"bar"}
    # returns
    # {"parcels"=>[{:test=>"yes"}], "Foo"=>"bar")

    def camelize_selected_keys(params)
      if params.is_a?(Hash)
        params.each_with_object({}) do |(key, value), new_hash|
          key = key.to_s
          if %w[to_address from_address parcels].include?(key)
            new_hash[key] = value
          else
            new_hash[key.camelcase] = camelize_selected_keys(value)
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

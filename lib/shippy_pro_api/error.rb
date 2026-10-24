# frozen_string_literal: true

module ShippyProAPI
  # Raised for every failure the gem reports, HTTP and API alike.
  class Error < StandardError
  end

  # Raised when ShippyPro reports a failure inside an HTTP 200 response body
  # (e.g. {"Error": "..."}). Carries the full parsed body for debugging.
  class ApiError < Error
    attr_reader :body

    def initialize(message, body = nil)
      @body = body
      super(message)
    end
  end
end

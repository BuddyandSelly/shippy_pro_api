# frozen_string_literal: true

require_relative "shippy_pro_api/version"

module ShippyProAPI
  autoload :Client, "shippy_pro_api/client"
  autoload :Error, "shippy_pro_api/error"
  autoload :ApiError, "shippy_pro_api/error"
  autoload :Object, "shippy_pro_api/object"
  autoload :Resource, "shippy_pro_api/resource"

  autoload :Rate, "shippy_pro_api/objects/rate"
  autoload :RateError, "shippy_pro_api/objects/rate_error"
  autoload :Rates, "shippy_pro_api/objects/rates"
  autoload :Shipment, "shippy_pro_api/objects/shipment"
  autoload :TrackingInfo, "shippy_pro_api/objects/tracking_info"

  autoload :ShipmentResource, "shippy_pro_api/resources/shipment"
end

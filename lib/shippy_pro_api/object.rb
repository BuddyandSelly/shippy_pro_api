# frozen_string_literal: true

require "active_support/core_ext/string"
require "ostruct"

module ShippyProAPI
  # Base class for the API responses: exposes ShippyPro's CamelCase payload as
  # underscored readers, recursively, so shipment.label_url reads "LabelURL".
  class Object < OpenStruct
    def initialize(attributes)
      super(to_ostruct(attributes))
    end

    def to_ostruct(obj)
      case obj
      when Hash
        OpenStruct.new(obj.to_h { |key, val| [key.to_s.underscore, to_ostruct(val)] })
      when Array
        obj.map { |o| to_ostruct(o) }
      else # Assumed to be a primitive value
        obj
      end
    end
  end
end

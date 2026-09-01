# ShippyProAPI [![CI](https://github.com/BuddyandSelly/shippy_pro_api/actions/workflows/test.yml/badge.svg)](https://github.com/BuddyandSelly/shippy_pro_api/actions/workflows/test.yml)

This is an API wrapper gem for ShippyPro API.

Requires Ruby 3.2 or newer; it is tested on 3.2 and on 4.0. Both faraday majors
work, from 1.10 up.

## Divergence from upstream (BuddyandSelly fork)

This fork ([PostCo/shippy_pro_api](https://github.com/PostCo/shippy_pro_api) upstream) carries the following changes, versioned as `0.2.1.buddy.N`:

- **Faraday 1.x compatibility** (`0.2.1.buddy.1`), since widened to faraday 2 as
  well: the json request and response middleware moved into faraday itself in
  1.10, so the `faraday_middleware` dependency (which never supported faraday 2)
  is gone and `faraday >= 1.10` covers both majors. CI runs the suite against
  both.
- **Acronym-correct request key serialization** (`0.2.1.buddy.2`): `carrier_id`, `transaction_id`, `rate_id`, and `api_orders_id` serialize to `CarrierID`, `TransactionID`, `RateID`, `APIOrdersID` (Rails camelize would produce `CarrierId` etc., which ShippyPro does not accept). `weight_unit` and `dimension_unit` are passed through in snake_case, matching ShippyPro's Ship API.
- **Errors inside HTTP 200 bodies raise `ShippyProAPI::ApiError`** (`0.2.1.buddy.2`): ShippyPro can report failures as `{"Error": "..."}`/`{"ErrorMessage": "..."}` with status 200; these now raise instead of returning a response object with no label. `ApiError < Error`, and carries the parsed body via `#body`.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add shippy_pro_api

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install shippy_pro_api

## Usage

A client must be initialized with ShippyPro's API key created for the user's account.

```ruby
client = ShippyProAPI::Client.new(api_key: ENV['SHIPPY_PRO_API_KEY'])
```

### Shipment

#### Create a shipment

```ruby
# params is a hash of shipment attributes in snake case
# note: the example below is not a complete list of attributes required to create a shipment

# example:
params = {
  to_address: {
    name: "John Doe",
    company: "ShippyPro",
    street1: "172 Boulevard de la Villette",
    street2: "19ème Arrondissement",
    city: "Paris",
    state: "",
    zip: "75019",
    country: "FR",
    phone: "+33186652533",
    email: "johndoe@gmail.com"
  },
  from_address: {
    name: "Jane Doe",
    company: "ProShippy",
    street1: "198 Avenue de France",
    street2: "",
    city: "Paris",
    state: "",
    zip: "75013",
    country: "FR",
    phone: "+33186652533",
    email: "janedoe@gmail.com"
  },
  parcels: [
    {
      length: 5,
      width: 5,
      height: 5,
      weight: 10
    }
  ],
  insurance: 0,
  insurance_currency: "EUR",
  cash_on_delivery: 0,
  cash_on_delivery_currency: "EUR",
  content_description: "Shoes",
  total_value: "50.25 EUR",
  shipping_service: "Standard"
}

# create a shipment
client.shipment.create(params)
```

#### Retrieve rates

```ruby
# params is a hash of shipment attributes in snake case

client.shipment.retrieve_rates(params)
```

#### Track a shipment

```ruby
client.shipment.track("tracking_number")
```

### Errors

Every failure raises a `ShippyProAPI::Error`. HTTP statuses ShippyPro documents
(400, 401, 403, 404, 429, 500, 503) are turned into a message describing the
status; anything else is handed back untouched.

ShippyPro also reports failures inside HTTP 200 bodies, as `{"Error": "..."}` or
`{"ErrorMessage": "..."}`. Those raise `ShippyProAPI::ApiError`, a subclass of
`ShippyProAPI::Error` that carries the parsed body:

```ruby
begin
  client.shipment.create(params)
rescue ShippyProAPI::ApiError => e
  e.message # => "CarrierID not found"
  e.body    # => {"Error" => "CarrierID not found", ...}
end
```

A populated `RatesErrors` array in a `GetRates` response is not a failure: one
carrier declining to quote is normal, so `retrieve_rates` returns it alongside
the rates. When ShippyPro sends neither key, both readers are `nil`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

`rake` runs the specs and RuboCop. The suite is measured by SimpleCov and fails
when line or branch coverage drops below 100%, so a new branch needs a new
example; CI publishes the two figures as a comment on the pull request.

To run the suite against the older faraday major:

    $ BUNDLE_GEMFILE=gemfiles/faraday1.gemfile bundle install
    $ BUNDLE_GEMFILE=gemfiles/faraday1.gemfile bundle exec rspec

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/PostCo/shippy_pro_api. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/PostCo/shippy_pro_api/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the ShippyProAPI project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/PostCo/shippy_pro_api/blob/main/CODE_OF_CONDUCT.md).

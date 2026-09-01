## [Unreleased]

### Changed

- Requires Ruby 3.2 or newer; the suite runs on 3.2 and on 4.0. `base64` and
  `ostruct` are declared as dependencies, since neither ships with Ruby any more.
- `faraday_middleware` is gone. Its json request and response middleware moved
  into faraday itself in 1.10, so `faraday >= 1.10` now covers both faraday
  majors, where the old `faraday_middleware ~> 1.0` pin held the gem to faraday 1.
- `activesupport` is no longer capped below 7.1; it is `>= 7.0`.
- `ShippyProAPI::Resource` keeps its constants out of the `private` section,
  where the modifier had no effect on them, and reads the request and response
  shapes with `case`/`when` instead of chained `is_a?` checks.

### Added

- A spec suite with 100% line and branch coverage, enforced by SimpleCov: the
  request serialization (acronym keys, snake_case passthrough keys, nested
  hashes and arrays, and a golden payload verified against Postman), every
  documented HTTP failure status, the errors ShippyPro hides in 200 bodies, and
  `retrieve_rates` and `track` including the responses that omit a key.
- CI runs the suite and RuboCop, publishes line and branch coverage as a comment
  on the pull request, and attaches the HTML report to the run. A second leg
  covers the oldest supported Ruby, and a third the older faraday major via
  `gemfiles/faraday1.gemfile`.
- Dependabot keeps the bundle and the workflow actions up to date.

## [0.1.0] - 2023-10-02

- Initial release

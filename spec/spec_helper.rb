# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch

  # Everything the gem ships has to be covered, whether it was loaded or not.
  cover "lib/**/*.rb"
  skip "lib/shippy_pro_api/version.rb"

  minimum_coverage line: 100, branch: 100
end

require "shippy_pro_api"
require "webmock/rspec"

WebMock.disable_net_connect!

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :random
end

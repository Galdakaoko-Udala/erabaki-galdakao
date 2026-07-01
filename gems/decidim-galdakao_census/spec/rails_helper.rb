# frozen_string_literal: true

require "spec_helper"
require "simplecov"
SimpleCov.start "rails"

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../../../config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "decidim/dev"

# The dummy app is the main application itself
Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "../../.."))

require "decidim/dev/test/base_spec_helper"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

# Gem-specific factories are now registered via
# config.factory_bot.definition_file_paths in the gem's Engine,
# so no manual Dir/require is needed here.

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: true)
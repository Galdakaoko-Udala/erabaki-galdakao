# frozen_string_literal: true

require "spec_helper"
require "simplecov"
SimpleCov.start "rails"
ENV["RAILS_ENV"] ||= "test"

# La gema no tiene su propia app: el entorno de Rails es la app principal,
# dos niveles por encima de esta carpeta spec/.
require File.expand_path("../../../config/environment", __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

require "decidim/dev"

# La dummy app es la app principal (mismo patrón que spec/rails_helper.rb de la raíz)
Decidim::Dev.dummy_app_path = File.expand_path(File.join(__dir__, "../../.."))

require "decidim/dev/test/base_spec_helper"

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

require "webmock/rspec"
WebMock.disable_net_connect!(allow_localhost: true)
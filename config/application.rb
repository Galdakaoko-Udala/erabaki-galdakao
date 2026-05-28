# frozen_string_literal: true
require_relative "boot"
# require 'rails/all'
require "decidim/rails"
# Add the frameworks used by your app that are not loaded by Decidim.
require "action_cable/engine"
# require "action_mailbox/engine"
# require "action_text/engine"
require_relative "../lib/decidim/galdakao_census/admin_engine"
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)
module DecidimApp
  class Application < Rails::Application
    config.load_defaults 7.2
  end
end

# frozen_string_literal: true

begin
  require "factory_bot_rails"
rescue LoadError
  # Not available in production; only used in test/dev to autoload factories.
end

module Decidim
  module GaldakaoCensus
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::GaldakaoCensus

      # Register this gem's factories so they are picked up by FactoryBot's
      # own load process instead of being required manually in rails_helper.rb,
      # where they could be overwritten by factory_bot_rails' auto-reload.
      config.factory_bot.definition_file_paths += [File.expand_path("../../../spec/factories", __dir__)] if defined?(FactoryBotRails)

      initializer "decidim_galdakao_census.verification_workflow" do
        Decidim::Verifications.register_workflow(:census_authorization_handler) do |workflow|
          workflow.form = "Decidim::GaldakaoCensus::CensusAuthorizationHandler"
          workflow.action_authorizer = "Decidim::GaldakaoCensus::CensusActionAuthorizer"
          workflow.renewable = true
          workflow.options do |options|
            options.attribute :zones, type: :string, required: false
          end
        end
      end

      config.to_prepare do
        require "decidim/galdakao_census/overrides/managed_user_error_event"

        Decidim::Verifications::ManagedUserErrorEvent.include(Decidim::GaldakaoCensus::Overrides::ManagedUserErrorEvent)
      end
    end
  end
end

# frozen_string_literal: true

begin
  require "factory_bot_rails"
rescue LoadError
  # No disponible en producción; solo se usa en test/dev para autoload de factories.
end

module Decidim
  module GaldakaoCensus
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::GaldakaoCensus

      # Register this gem's factories so they are picked up by FactoryBot's
      # own load process instead of being required manually in rails_helper.rb,
      # where they could be overwritten by factory_bot_rails' auto-reload.
      config.factory_bot.definition_file_paths += [File.expand_path("../../../spec/factories", __dir__)] if defined?(FactoryBotRails)

      initializer "galdakao_census.verification_workflow" do
        Decidim::Verifications.register_workflow(:census_authorization_handler) do |workflow|
          workflow.form = "CensusAuthorizationHandler"
          workflow.action_authorizer = "CensusActionAuthorizer"
          workflow.renewable = false
          workflow.options do |options|
            options.attribute :zones, type: :string, required: false
          end
        end
      end

      config.to_prepare do
        Decidim::Verifications::ManagedUserErrorEvent.class_eval do
          include Rails.application.routes.mounted_helpers

          def resource_path
            nil
          end

          def resource_url
            nil
          end

          def resource_title
            nil
          end

          def default_i18n_options
            super.merge({ conflicts_path: decidim_admin.conflicts_path,
                          conflicts_url: decidim_admin.conflicts_url })
          end

          private

          def decidim_admin
            @decidim_admin ||= Decidim::EngineRouter.new("decidim_admin", { host: organization.host })
          end

          def organization
            resource.current_user.organization
          end
        end
      end
    end
  end
end

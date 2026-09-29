# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::GaldakaoCensus::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil
      paths["app/overrides"] ||= ["app/overrides"]

      routes do
        resources :streets, only: [:index] do
          collection do
            get :manage
            post :sync
          end
        end

        resources :zones do
          resources :zone_streets, except: [:index, :show]
        end

        resources :blocked_users, only: [:index] do
          member do
            patch :unlock
          end
        end
      end

      initializer "decidim_galdakao_census_admin.mount_routes" do |_app|
        Decidim::Core::Engine.routes do
          mount Decidim::GaldakaoCensus::AdminEngine, at: "/admin/galdakao_census", as: "decidim_admin_galdakao_census"
        end
      end

      initializer "decidim_galdakao_census_admin.menu" do
        Decidim.menu :workflows_menu do |menu|
          menu.add_item :galdakao_census_blocked_users,
                        I18n.t("menu.blocked_users", scope: "decidim.galdakao_census.admin"),
                        decidim_admin_galdakao_census.blocked_users_path,
                        active: is_active_link?(decidim_admin_galdakao_census.blocked_users_path)
        end
      end
    end
  end
end

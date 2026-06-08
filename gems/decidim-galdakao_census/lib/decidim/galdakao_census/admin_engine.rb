# frozen_string_literal: true
module Decidim
  module GaldakaoCensus
    module Admin
    end
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::GaldakaoCensus::Admin
      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil
      paths["app/overrides"] ||= ["app/overrides"]
      routes do
        resources :galdakao, only: [:index] do
          collection do
            get  :streets
            post :sync
            post :check
          end
        end
        scope "/galdakao", as: :galdakao do
          resources :zones do
            resources :zone_streets
          end
          resources :blocked_users, only: [:index] do
            member do
              delete :unlock
            end
          end
        end
      end
      initializer "galdakao_census.admin_mount_routes" do |_app|
        Decidim::Core::Engine.routes do
          mount Decidim::GaldakaoCensus::AdminEngine, at: "/admin/galdakao_census", as: "decidim_admin_galdakao_census"
        end
      end
      initializer "galdakao_census.admin_blocked_users_menu" do
        Decidim.menu :workflows_menu do |menu|
          menu.add_item :blocked_users,
                        I18n.t("decidim.admin.galdakao.blocked_users.index.menu_label"),
                        decidim_admin_galdakao_census.galdakao_blocked_users_path,
                        active: is_active_link?(decidim_admin_galdakao_census.galdakao_blocked_users_path)
        end
      end
    end
  end
end

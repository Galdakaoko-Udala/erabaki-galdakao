# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::GaldakaoCensus::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil
      paths["app/overrides"] ||= ["app/overrides"]

      routes do
        root to: "connections#show"

        resources :streets, only: [:index] do
          collection do
            get :manage
            post :sync
          end
        end

        resources :zones do
          resources :zone_streets, except: [:index, :show]
        end

        resource :connection, only: [:show] do
          post :check
        end

        resources :blocked_users, only: [:index] do
          member do
            patch :unlock
          end
        end
      end

      initializer "decidim_galdakao_census_admin.mount_routes" do |_app|
        Decidim::Core::Engine.routes do
          extend Decidim::Routes::LocaleRedirects

          scope "/:locale", **locale_scope_options do
            mount Decidim::GaldakaoCensus::AdminEngine, at: "/admin/galdakao_census", as: "decidim_admin_galdakao_census"
          end
        end
      end

      initializer "decidim_galdakao_census_admin.register_icons" do
        Decidim.icons.register(name: "dashboard-2-line", icon: "dashboard-2-line", category: "system", description: "", engine: :galdakao_census)
      end

      initializer "decidim_galdakao_census_admin.admin_menu" do
        Decidim.menu :admin_menu do |menu|
          menu.add_item :galdakao_census,
                        I18n.t("menu.census", scope: "decidim.galdakao_census.admin"),
                        decidim_admin_galdakao_census.connection_path,
                        icon_name: "dashboard-2-line",
                        position: 1.2,
                        active: is_active_link?(decidim_admin_galdakao_census.root_path, :inclusive),
                        # Rendered from any admin page, whose permission chain does not include the census one
                        if: allowed_to?(:update, :organization, organization: current_organization)
        end
      end

      initializer "decidim_galdakao_census_admin.menu" do
        Decidim.menu :admin_galdakao_census_menu do |menu|
          # Not a link: the title of the secondary menu
          menu.add_item :title,
                        I18n.t("menu.sync", scope: "decidim.galdakao_census.admin"),
                        "#",
                        position: 1

          menu.add_item :streets,
                        I18n.t("menu.streets", scope: "decidim.galdakao_census.admin"),
                        decidim_admin_galdakao_census.manage_streets_path,
                        position: 3,
                        active: is_active_link?(decidim_admin_galdakao_census.streets_path, :inclusive),
                        if: allowed_to?(:read, :census_street)

          menu.add_item :zones,
                        I18n.t("menu.zones", scope: "decidim.galdakao_census.admin"),
                        decidim_admin_galdakao_census.zones_path,
                        position: 4,
                        active: is_active_link?(decidim_admin_galdakao_census.zones_path, :inclusive),
                        if: allowed_to?(:read, :census_zone)

          menu.add_item :blocked_users,
                        I18n.t("menu.blocked_users", scope: "decidim.galdakao_census.admin"),
                        decidim_admin_galdakao_census.blocked_users_path,
                        position: 5,
                        active: is_active_link?(decidim_admin_galdakao_census.blocked_users_path),
                        if: allowed_to?(:read, :census_blocked_user)

          menu.add_item :check,
                        I18n.t("menu.check", scope: "decidim.galdakao_census.admin"),
                        decidim_admin_galdakao_census.connection_path,
                        position: 2,
                        active: is_active_link?(decidim_admin_galdakao_census.connection_path, :inclusive),
                        if: allowed_to?(:read, :census_connection)
        end
      end
    end
  end
end

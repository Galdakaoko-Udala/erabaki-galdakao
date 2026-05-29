# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
    end

    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::GaldakaoCensus::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

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
        end
      end

      initializer "galdakao_census.admin_mount_routes" do |_app|
        Decidim::Core::Engine.routes do
          mount Decidim::GaldakaoCensus::AdminEngine, at: "/admin/galdakao_census", as: "decidim_admin_galdakao_census"
        end
      end
    end
  end
end

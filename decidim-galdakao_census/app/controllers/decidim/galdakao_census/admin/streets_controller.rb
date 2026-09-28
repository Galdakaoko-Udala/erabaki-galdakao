# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Lists the streets synced from the municipal register and syncs them again.
      class StreetsController < Admin::ApplicationController
        include Decidim::Paginable

        helper_method :streets, :last_sync, :last_sync_class

        def index
          enforce_permission_to :read, :census_street
        end

        def sync
          enforce_permission_to :sync, :census_street

          if Street.import_streets!(current_organization)
            flash[:notice] = I18n.t("streets.sync.success", scope: "decidim.galdakao_census.admin")
          else
            flash[:alert] = I18n.t("streets.sync.error", scope: "decidim.galdakao_census.admin")
          end

          redirect_to streets_path
        end

        private

        def organization_streets
          Street.where(organization: current_organization)
        end

        def streets
          @streets ||= paginate(organization_streets.order(:name))
        end

        def last_sync
          @last_sync ||= organization_streets.maximum(:updated_at)
        end

        def last_sync_class(datetime)
          return unless datetime
          return "alert" if datetime < 1.week.ago
          return "warning" if datetime < 1.day.ago

          "success"
        end

        def per_page
          50
        end
      end
    end
  end
end

# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Manages the streets synced from the municipal register: a panel to sync them and their list.
      class StreetsController < Admin::ApplicationController
        include Decidim::Paginable

        helper_method :streets, :last_sync, :last_sync_class

        def manage
          enforce_permission_to :read, :census_street
        end

        def index
          enforce_permission_to :read, :census_street
        end

        def sync
          enforce_permission_to :sync, :census_street

          if Street.import_streets!(current_organization)
            flash[:notice] = I18n.t("streets.sync.success", scope: "decidim.galdakao_census.admin")
            redirect_to streets_path
          else
            flash[:alert] = I18n.t("streets.sync.error", scope: "decidim.galdakao_census.admin")
            redirect_to manage_streets_path
          end
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
      end
    end
  end
end

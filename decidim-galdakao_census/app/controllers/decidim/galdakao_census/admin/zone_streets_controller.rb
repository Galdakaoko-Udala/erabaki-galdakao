# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Manages the streets (and portal numbers) included in a zone.
      class ZoneStreetsController < Admin::ApplicationController
        helper_method :zone, :zone_street

        def new
          enforce_permission_to :create, :census_zone_street
          @form = form(ZoneStreetForm).instance(zone:)
        end

        def create
          enforce_permission_to :create, :census_zone_street
          @form = form(ZoneStreetForm).from_params(params, zone:)

          CreateZoneStreet.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("zone_streets.create.success", scope: "decidim.galdakao_census.admin")
              redirect_to zone_path(zone)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("zone_streets.create.invalid", scope: "decidim.galdakao_census.admin")
              render :new, status: :unprocessable_entity
            end
          end
        end

        def edit
          enforce_permission_to :update, :census_zone_street
          @form = form(ZoneStreetForm).from_model(zone_street, zone:)
        end

        def update
          enforce_permission_to :update, :census_zone_street
          @form = form(ZoneStreetForm).from_params(params, zone:)

          UpdateZoneStreet.call(@form, zone_street) do
            on(:ok) do
              flash[:notice] = I18n.t("zone_streets.update.success", scope: "decidim.galdakao_census.admin")
              redirect_to zone_path(zone)
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("zone_streets.update.invalid", scope: "decidim.galdakao_census.admin")
              render :edit, status: :unprocessable_entity
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :census_zone_street

          DestroyZoneStreet.call(zone_street, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("zone_streets.destroy.success", scope: "decidim.galdakao_census.admin")
            end

            on(:invalid) do
              flash[:alert] = I18n.t("zone_streets.destroy.invalid", scope: "decidim.galdakao_census.admin")
            end
          end

          redirect_to zone_path(zone)
        end

        private

        def zone
          @zone ||= Zone.where(organization: current_organization).find(params[:zone_id])
        end

        def zone_street
          @zone_street ||= zone.zone_streets.find(params[:id])
        end
      end
    end
  end
end

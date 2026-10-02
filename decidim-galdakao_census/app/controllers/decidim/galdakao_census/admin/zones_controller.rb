# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Manages the zones used to restrict permissions by address.
      class ZonesController < Admin::ApplicationController
        include Decidim::Paginable

        helper_method :zones, :zone

        def index
          enforce_permission_to :read, :census_zone

          respond_to do |format|
            format.html
            format.json { render json: json_zones }
          end
        end

        def show
          enforce_permission_to :read, :census_zone
        end

        def new
          enforce_permission_to :create, :census_zone
          @form = form(ZoneForm).instance
        end

        def create
          enforce_permission_to :create, :census_zone
          @form = form(ZoneForm).from_params(params)

          CreateZone.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("zones.create.success", scope: "decidim.galdakao_census.admin")
              redirect_to zones_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("zones.create.invalid", scope: "decidim.galdakao_census.admin")
              render :new, status: :unprocessable_entity
            end
          end
        end

        def edit
          enforce_permission_to :update, :census_zone
          @form = form(ZoneForm).from_model(zone)
        end

        def update
          enforce_permission_to :update, :census_zone
          @form = form(ZoneForm).from_params(params)

          UpdateZone.call(@form, zone) do
            on(:ok) do
              flash[:notice] = I18n.t("zones.update.success", scope: "decidim.galdakao_census.admin")
              redirect_to zones_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("zones.update.invalid", scope: "decidim.galdakao_census.admin")
              render :edit, status: :unprocessable_entity
            end
          end
        end

        def destroy
          enforce_permission_to :destroy, :census_zone

          DestroyZone.call(zone, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("zones.destroy.success", scope: "decidim.galdakao_census.admin")
            end

            on(:invalid) do
              flash[:alert] = I18n.t("zones.destroy.invalid", scope: "decidim.galdakao_census.admin")
            end
          end

          redirect_to zones_path
        end

        private

        def organization_zones
          Zone.where(organization: current_organization).order(:name)
        end

        def zone
          @zone ||= organization_zones.find(params[:id])
        end

        def zones
          @zones ||= paginate(organization_zones.includes(:zone_streets))
        end

        # Not paginated: the permissions zone selector needs to search every zone
        def json_zones
          query = if params[:ids]
                    organization_zones.where(id: params[:ids].split(","))
                  else
                    organization_zones.where("name ILIKE ?", "%#{Zone.sanitize_sql_like(params[:q].to_s)}%")
                  end
          query.map { |zone| { id: zone.id, text: zone.name } }
        end
      end
    end
  end
end

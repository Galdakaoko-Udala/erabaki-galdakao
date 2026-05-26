# frozen_string_literal: true
module Decidim
  module Admin
    class ZoneStreetsController < GaldakaoController
      layout "decidim/admin/application"
      helper_method :zone, :zone_street
      before_action -> { enforce_permission_to :read, :admin_user }
      def new
        @form = form(GaldakaoZoneStreetForm).instance
      end
      def edit
        @form = form(GaldakaoZoneStreetForm).from_model(zone_street)
      end
      def create
        @form = form(GaldakaoZoneStreetForm).from_params(params)
        CreateGaldakaoZoneStreet.call(@form, zone) do
          on(:ok) do
            flash[:notice] = t("decidim.admin.galdakao.zone_streets.create.success")
            redirect_to decidim_admin.galdakao_zone_path(zone)
          end
          on(:invalid) do |error|
            flash.now[:alert] = t("decidim.admin.galdakao.zone_streets.create.error", error: error)
            render :new
          end
        end
      end
      def update
        @form = form(GaldakaoZoneStreetForm).from_params(params)
        UpdateGaldakaoZoneStreet.call(@form, zone_street) do
          on(:ok) do
            flash[:notice] = t("decidim.admin.galdakao.zone_streets.update.success")
            redirect_to decidim_admin.galdakao_zone_path(zone)
          end
          on(:invalid) do |error|
            flash.now[:alert] = t("decidim.admin.galdakao.zone_streets.update.error", error: error)
            render :edit
          end
        end
      end
      def destroy
        zone_street.destroy!
        flash[:notice] = t("decidim.admin.galdakao.zone_streets.destroy.success")
        redirect_to decidim_admin.galdakao_zone_path(zone)
      end
      private
      def zone
        @zone ||= GaldakaoZone.find(params[:zone_id])
      end
      def zone_street
        @zone_street ||= zone.zone_streets.find(params[:id])
      end
    end
  end
end

# frozen_string_literal: true
module Decidim
  module Admin
    class ZonesController < GaldakaoController
      include Paginable
      layout "decidim/admin/application"
      helper_method :zone_list, :zone

      before_action -> { enforce_permission_to :read, :admin_user }

      def index
        respond_to do |format|
          format.html
          format.json { render json: json_zones }
        end
      end

      def show
        @zone = zone
      end

      def new
        @form = form(GaldakaoZoneForm).instance
      end

      def edit
        @form = form(GaldakaoZoneForm).from_model(zone)
      end

      def create
        @form = form(GaldakaoZoneForm).from_params(params)
        CreateGaldakaoZone.call(@form) do
          on(:ok) do
            flash[:notice] = t("decidim.admin.galdakao.zones.create.success")
            redirect_to decidim_admin.galdakao_zones_path
          end
          on(:invalid) do |error|
            flash.now[:alert] = t("decidim.admin.galdakao.zones.create.error", error: error)
            render :new
          end
        end
      end

      def update
        @form = form(GaldakaoZoneForm).from_params(params)
        UpdateGaldakaoZone.call(@form, zone) do
          on(:ok) do
            flash[:notice] = t("decidim.admin.galdakao.zones.update.success")
            redirect_to decidim_admin.galdakao_zones_path
          end
          on(:invalid) do |error|
            flash.now[:alert] = t("decidim.admin.galdakao.zones.update.error", error: error)
            render :edit
          end
        end
      end

      def destroy
        zone.destroy!
        flash[:notice] = t("decidim.admin.galdakao.zones.destroy.success")
        redirect_to decidim_admin.galdakao_zones_path
      end

      private

      def zone
        @zone ||= GaldakaoZone.find(params[:id])
      end

      def json_zones
        query = zone_list
        query = if params[:ids]
                  query.where(id: params[:ids].split(","))
                else
                  query.where("name ILIKE ?", "%#{params[:q]}%")
                end
        query.map { |z| { id: z.id, text: z.name } }
      end

      def zone_list
        paginate(GaldakaoZone.where(organization: current_organization).order(name: :asc))
      end

      def per_page
        50
      end
    end
  end
end

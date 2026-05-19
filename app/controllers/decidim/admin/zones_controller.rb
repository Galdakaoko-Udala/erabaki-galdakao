# frozen_string_literal: true

module Decidim
  module Admin
    class ZonesController < GaldakaoApplicationController
      include Paginable
      layout "decidim/admin/application"

      helper_method :zone_list, :streets, :zone

      before_action -> { enforce_permission_to :read, :admin_user }

      def index
        respond_to do |format|
          format.html
          format.json { render json: json_zones }
        end
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
            flash[:notice] = "Nueva zona creada correctamente"
            redirect_to decidim_admin.galdakao_zones_path
          end
          on(:invalid) do |error|
            flash.now[:alert] = "Error al crear la zona: #{error}"
            render :new
          end
        end
      end

      def update
        @form = form(GaldakaoZoneForm).from_params(params)
        UpdateGaldakaoZone.call(@form) do
          on(:ok) do
            flash[:notice] = "Zona actualizada correctamente"
            redirect_to decidim_admin.galdakao_zones_path
          end
          on(:invalid) do |error|
            flash.now[:alert] = "Error al actualizar la zona: #{error}"
            render :edit
          end
        end
      end

      def destroy
        zone.destroy!
        flash[:notice] = "Zona eliminada correctamente"
        redirect_to decidim_admin.galdakao_zones_path
      end

      private

      def zone
        @zone ||= GaldakaoZone.find(params[:id])
      end

      def streets
        GaldakaoStreet.where(organization: current_organization).order(name: :asc)
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
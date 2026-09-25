# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      class GaldakaoController < Decidim::Admin::ApplicationController
        include Paginable
        layout "decidim/admin/users"

        helper_method :streets_list, :last_sync, :last_sync_class, :service

        def index
          enforce_permission_to :read, :admin_user
          @form = form(CensusAuthorizationHandler).instance
        end

        def check
          enforce_permission_to :read, :admin_user
          @form = form(CensusAuthorizationHandler).from_params(params)
          @response = @form.slim_response
          render :index
        end

        def streets
          enforce_permission_to :read, :admin_user
          respond_to do |format|
            format.html
            format.json { render json: json_streets }
          end
        end

        def sync
          enforce_permission_to :read, :admin_user
          GaldakaoStreet.import_streets!(current_organization)
          redirect_to decidim_admin_galdakao_census.streets_galdakao_index_path,
                      notice: I18n.t("decidim.admin.galdakao.sync.success")
        end

        private

        def service(action: "TestDBConnection")
          @service ||= GaldakaoWebservice.new(action)
        end

        def json_streets
          query = streets_list
          query = if params[:ids]
                    query.where(id: params[:ids])
                  else
                    query.where("name ILIKE ?", "%#{params[:q]}%")
                  end
          query.map { |item| { id: item.id, text: item.name } }
        end

        def streets_list
          paginate(GaldakaoStreet.where(organization: current_organization).order(name: :asc))
        end

        def last_sync
          @last_sync ||= GaldakaoStreet
                         .where(organization: current_organization)
                         .select(:updated_at)
                         .order(updated_at: :desc)
                         .last&.updated_at
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

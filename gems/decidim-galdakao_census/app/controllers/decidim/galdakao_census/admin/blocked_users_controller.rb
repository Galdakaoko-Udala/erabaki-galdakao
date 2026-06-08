# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      class BlockedUsersController < Decidim::Admin::ApplicationController
        layout "decidim/admin/users"
        def index
          @blocked_users = Decidim::GaldakaoCensus::LockoutManager.blocked_users(current_organization)
        end

        def unlock
          @user = Decidim::User.find(params[:id])
          lockout_manager = Decidim::GaldakaoCensus::LockoutManager.new(@user)

          if lockout_manager.locked_indefinitely?
            lockout_manager.register_success
            flash[:notice] = t("decidim.admin.galdakao.blocked_users.unlock.success")
          else
            flash[:alert] = t("decidim.admin.galdakao.blocked_users.unlock.not_blocked")
          end

          redirect_to decidim_admin_galdakao_census.galdakao_blocked_users_path
        end
      end
    end
  end
end

# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Lists the users blocked indefinitely after too many failed verifications and unblocks them.
      class BlockedUsersController < Admin::ApplicationController
        helper_method :blocked_users, :lockout_data, :last_attempt_at

        def index
          enforce_permission_to :read, :census_blocked_user
        end

        def unlock
          enforce_permission_to :unlock, :census_blocked_user

          user = Decidim::User.where(organization: current_organization).find(params[:id])
          lockout_manager = LockoutManager.new(user)

          if lockout_manager.locked_indefinitely?
            lockout_manager.register_success
            flash[:notice] = I18n.t("blocked_users.unlock.success", scope: "decidim.galdakao_census.admin")
          else
            flash[:alert] = I18n.t("blocked_users.unlock.not_blocked", scope: "decidim.galdakao_census.admin")
          end

          redirect_to blocked_users_path
        end

        private

        def blocked_users
          @blocked_users ||= LockoutManager.blocked_users(current_organization)
        end

        def lockout_data(user)
          user.extended_data.dig("authorizations", LockoutManager::HANDLER_KEY) || {}
        end

        def last_attempt_at(user)
          value = lockout_data(user)["last_attempt_at"]
          Time.zone.parse(value.to_s) if value.present?
        rescue ArgumentError
          nil
        end
      end
    end
  end
end

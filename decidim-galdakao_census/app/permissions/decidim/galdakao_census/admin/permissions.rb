# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Only the organization admins can manage the census streets, zones and blocked users.
      class Permissions < Decidim::DefaultPermissions
        ALLOWED_ACTIONS = {
          census_street: [:read, :sync],
          census_zone: [:read, :create, :update, :destroy],
          census_zone_street: [:create, :update, :destroy],
          census_blocked_user: [:read, :unlock]
        }.freeze

        def permissions
          return permission_action unless permission_action.scope == :admin
          return permission_action unless ALLOWED_ACTIONS.fetch(permission_action.subject, []).include?(permission_action.action)

          allow! if user&.admin? && user.admin_terms_accepted?
          permission_action
        end
      end
    end
  end
end

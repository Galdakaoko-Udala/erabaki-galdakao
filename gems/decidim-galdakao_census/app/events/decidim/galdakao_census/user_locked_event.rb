# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    class UserLockedEvent < Decidim::Events::SimpleEvent
      include Rails.application.routes.mounted_helpers

      def i18n_scope
        "decidim.events.galdakao_census.user_locked"
      end

      def resource_path
        nil
      end

      def resource_url
        nil
      end

      def resource_title
        nil
      end

      def default_i18n_options
        super.merge({
          blocked_users_path: decidim_admin.galdakao_blocked_users_path
        })
      end

      private

      def decidim_admin
        @decidim_admin ||= Decidim::EngineRouter.new("decidim_admin", { host: organization.host })
      end

      def organization
        resource.organization
      end
    end
  end
end

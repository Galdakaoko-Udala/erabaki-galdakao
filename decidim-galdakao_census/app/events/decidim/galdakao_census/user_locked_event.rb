# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    # Notifies the organization admins that a participant has been blocked indefinitely
    # after too many failed verification attempts.
    class UserLockedEvent < Decidim::Events::SimpleEvent
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

      # A full URL, as the link is also sent by email
      def default_i18n_options
        super.merge(blocked_users_url: decidim_admin_galdakao_census.blocked_users_url)
      end

      private

      def decidim_admin_galdakao_census
        @decidim_admin_galdakao_census ||= Decidim::EngineRouter.new("decidim_admin_galdakao_census", { host: organization.host })
      end

      def organization
        resource.organization
      end
    end
  end
end

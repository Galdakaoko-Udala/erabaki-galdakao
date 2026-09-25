# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    class LockoutManager
      HANDLER_KEY = "census_authorization_handler"
      MAX_ATTEMPTS = 6
      SOFT_LOCK_TIME = 30.seconds
      HARD_LOCK_TIME = 5.minutes
      INFINITE = "infinite"

      def initialize(user)
        @user = user
      end

      # Devuelve nil si no hay bloqueo activo.
      # Devuelve un mensaje de error si el usuario está bloqueado.
      def check_lockout
        return nil unless auth_data["locked_until"]

        locked_until = auth_data["locked_until"]

        if locked_until == INFINITE
          I18n.t("decidim.galdakao_census.lockout.blocked_indefinitely")
        elsif Time.zone.parse(locked_until.to_s) > Time.current
          remaining = (Time.zone.parse(locked_until.to_s) - Time.current).to_i
          minutes = remaining / 60
          seconds = remaining % 60
          I18n.t("decidim.galdakao_census.lockout.wait",
                 minutes: minutes, seconds: seconds)
        end
      end

      def register_failed_attempt
        failed_attempts = (auth_data["failed_attempts"] || 0) + 1

        locked_until, message = lock_params_for(failed_attempts)

        update_auth_data(
          "failed_attempts" => failed_attempts,
          "last_attempt_at" => Time.current,
          "locked_until" => locked_until
        )

        notify_admin if locked_until == INFINITE

        message
      end

      def register_success
        data = user.extended_data["authorizations"] || {}
        data.delete(HANDLER_KEY)
        user.update(extended_data: user.extended_data.merge("authorizations" => data))
      end

      def locked_indefinitely?
        auth_data["locked_until"] == INFINITE
      end

      def self.blocked_users(organization)
        Decidim::User.where(decidim_organization_id: organization.id).select do |u|
          data = u.extended_data.dig("authorizations", HANDLER_KEY)
          next false unless data

          data["locked_until"] == INFINITE
        end
      end

      private

      attr_reader :user

      def auth_data
        @auth_data ||= user.extended_data.dig("authorizations", HANDLER_KEY) || {}
      end

      def update_auth_data(new_data)
        data = user.extended_data["authorizations"] || {}
        data[HANDLER_KEY] = new_data
        user.update(extended_data: user.extended_data.merge("authorizations" => data))
        @auth_data = new_data
      end

      def lock_params_for(failed_attempts)
        case failed_attempts
        when 1..2, 4..5
          wait_msg = wait_message(SOFT_LOCK_TIME)
          message = "#{wait_msg}#{I18n.t("decidim.galdakao_census.lockout.attempts_remaining", remaining: MAX_ATTEMPTS - failed_attempts)}"
          [Time.current + SOFT_LOCK_TIME, message]
        when 3
          wait_msg = wait_message(HARD_LOCK_TIME)
          message = "#{wait_msg}#{I18n.t("decidim.galdakao_census.lockout.three_attempts")}"
          [Time.current + HARD_LOCK_TIME, message]
        else
          [INFINITE, I18n.t("decidim.galdakao_census.lockout.blocked_indefinitely_contact")]
        end
      end

      def wait_message(lock_time)
        minutes = lock_time.to_i / 60
        seconds = lock_time.to_i % 60
        "#{I18n.t("decidim.galdakao_census.lockout.wait", minutes: minutes, seconds: seconds)}\n"
      end

      def notify_admin
        Decidim::EventsManager.publish(
          event: "decidim.events.galdakao_census.user_locked",
          event_class: Decidim::GaldakaoCensus::UserLockedEvent,
          resource: user,
          affected_users: user.organization.admins
        )
      end
    end
  end
end

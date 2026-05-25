Rails.application.config.after_initialize do
  Decidim::ActionAuthorizer::AuthorizationStatus.class_eval do
    def current_path(redirect_url: nil)
      return nil if unauthorized?
      return unless @authorization_handler
      if pending?
        @authorization_handler.resume_authorization_path(redirect_url:)
      else
        @authorization_handler.root_path(redirect_url:)
      end
    end
  end

  Decidim::Verifications::AuthorizationsController.class_eval do
    def onboarding_pending
      return redirect_back(fallback_location: decidim_verifications.authorizations_path) unless onboarding_manager.valid?

      authorizations = action_authorized_to(onboarding_manager.action, **onboarding_manager.action_authorized_resources)
      authorization_status = authorizations.global_code

      if authorization_status == :unauthorized
        flash[:alert] = t("census_authorization_handler.unauthorized_zone", scope: "decidim.authorization_handlers")
        redirect_path = onboarding_manager.component_path || onboarding_manager.finished_redirect_path || decidim.root_path
        clear_onboarding_data!(current_user)
        return redirect_to redirect_path
      end

      if authorizations.single_authorization_required?
        flash.keep
        return redirect_to(authorizations.statuses.first.current_path(redirect_url: decidim_verifications.onboarding_pending_authorizations_path))
      end

      return unless onboarding_manager.finished_verifications?(active_authorization_methods) || authorization_status == :unauthorized

      clear_onboarding_data!(current_user)
      redirect_to onboarding_manager.finished_redirect_path
    end

    private

    def active_authorization_methods
      Decidim::Verifications::Authorizations.new(organization: current_organization, user: current_user, granted: true).query.pluck(:name)
    end
  end
end

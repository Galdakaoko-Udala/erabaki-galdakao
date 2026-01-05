# frozen_string_literal: true

if Decidim.module_installed? :verifications
  Decidim::Verifications.register_workflow(:census_authorization_handler) do |workflow|
    workflow.form = "CensusAuthorizationHandler"
    workflow.action_authorizer = "CensusActionAuthorizer"
    workflow.options do |options|
      options.attribute :zones, type: :string, required: false
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe Decidim::Admin::AuthorizationWorkflowsController do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization, available_authorizations: ["census_authorization_handler"]) }
  let(:routes) { Decidim::GaldakaoCensus::AdminEngine.routes.url_helpers }

  before do
    host! organization.host
    sign_in create(:user, :admin, :confirmed, organization:)
  end

  it "adds the links to manage the census streets and zones" do
    get "/admin/authorization_workflows"

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation_missing")
    expect(response.body).to include(%(href="#{routes.streets_path}"))
    expect(response.body).to include(%(href="#{routes.zones_path}"))
  end
end

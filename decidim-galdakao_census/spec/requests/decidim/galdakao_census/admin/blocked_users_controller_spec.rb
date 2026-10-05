# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::BlockedUsersController do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:routes) { Decidim::GaldakaoCensus::AdminEngine.routes.url_helpers }
  let(:lockout_data) do
    { "authorizations" => { "census_authorization_handler" => { "locked_until" => "infinite", "failed_attempts" => 6 } } }
  end
  let!(:locked_user) do
    create(:user, :confirmed, organization:, email: "locked@example.org", extended_data: lockout_data)
  end

  before { host! organization.host }

  def locked?(user)
    user.reload.extended_data.dig("authorizations", "census_authorization_handler").present?
  end

  shared_examples "denies access to blocked users" do
    it "does not list the blocked users" do
      get routes.blocked_users_path

      expect(response).to have_http_status(:redirect)
      expect(response.body).not_to include("locked@example.org")
    end

    it "does not unlock the user" do
      patch routes.unlock_blocked_user_path(locked_user)

      expect(response).to have_http_status(:redirect)
      expect(locked?(locked_user)).to be(true)
    end
  end

  context "when the visitor is not signed in" do
    it_behaves_like "denies access to blocked users"
  end

  context "when the user is not an admin" do
    before { sign_in create(:user, :confirmed, organization:) }

    it_behaves_like "denies access to blocked users"
  end

  context "when the user is an admin" do
    before { sign_in create(:user, :admin, :confirmed, organization:) }

    it "lists the blocked users" do
      get routes.blocked_users_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("translation_missing")
      expect(response.body).to include("locked@example.org")
    end

    it "unlocks a user of the organization" do
      patch routes.unlock_blocked_user_path(locked_user)

      expect(locked?(locked_user)).to be(false)
    end

    it "does not unlock a user of another organization" do
      other_locked_user = create(:user, :confirmed, organization: create(:organization), extended_data: lockout_data)

      patch routes.unlock_blocked_user_path(other_locked_user)

      expect(response).to have_http_status(:not_found)
      expect(locked?(other_locked_user)).to be(true)
    end
  end
end

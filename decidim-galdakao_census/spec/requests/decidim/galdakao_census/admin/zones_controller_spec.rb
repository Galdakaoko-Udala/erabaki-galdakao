# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::ZonesController do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:routes) { Decidim::GaldakaoCensus::AdminEngine.routes.url_helpers }
  let(:other_zone) { create(:galdakao_zone, organization: create(:organization)) }

  before do
    host! organization.host
    sign_in create(:user, :admin, :confirmed, organization:)
  end

  context "when the zone belongs to another organization" do
    it "does not show the zone" do
      get routes.galdakao_zone_path(other_zone)

      expect(response).to have_http_status(:not_found)
    end

    it "does not destroy the zone" do
      delete routes.galdakao_zone_path(other_zone)

      expect(response).to have_http_status(:not_found)
      expect(Decidim::GaldakaoCensus::GaldakaoZone.exists?(other_zone.id)).to be(true)
    end

    it "does not show the form to add streets to the zone" do
      get routes.new_galdakao_zone_zone_street_path(other_zone)

      expect(response).to have_http_status(:not_found)
    end
  end
end

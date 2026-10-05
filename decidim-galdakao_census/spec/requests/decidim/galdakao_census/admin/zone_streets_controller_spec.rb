# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::ZoneStreetsController do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:routes) { Decidim::GaldakaoCensus::AdminEngine.routes.url_helpers }
  let(:zone) { create(:census_zone, organization:) }
  let!(:street) { create(:census_street, organization:, name: "Kale Nagusia") }

  before do
    host! organization.host
    sign_in create(:user, :admin, :confirmed, organization:)
  end

  it "renders the new form with the organization streets" do
    create(:census_street, name: "Other organization street")

    get routes.new_zone_zone_street_path(zone)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation_missing")
    expect(response.body).to include("Kale Nagusia")
    expect(response.body).not_to include("Other organization street")
  end

  it "renders the edit form" do
    zone_street = create(:census_zone_street, zone:, street:, organization:)

    get routes.edit_zone_zone_street_path(zone, zone_street)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation_missing")
  end

  it "adds a street to the zone and registers it in the admin log" do
    params = { zone_street: { street_id: street.id, numbers_constraint: "only_range", numbers_range: "1-20" } }

    expect { post routes.zone_zone_streets_path(zone), params: }
      .to change(zone.zone_streets, :count).by(1)
      .and change(Decidim::ActionLog, :count).by(1)

    expect(response).to redirect_to(routes.zone_path(zone))
    expect(zone.zone_streets.last.numbers_range).to eq("1-20")
  end

  it "renders the form with an error status when the range is missing" do
    params = { zone_street: { street_id: street.id, numbers_constraint: "only_range", numbers_range: "" } }

    post routes.zone_zone_streets_path(zone), params: params

    expect(response).to have_http_status(:unprocessable_entity)
    expect(zone.zone_streets).to be_empty
  end

  it "removes a street from the zone" do
    zone_street = create(:census_zone_street, zone:, street:, organization:)

    expect { delete routes.zone_zone_street_path(zone, zone_street) }.to change(Decidim::ActionLog, :count).by(1)
    expect(zone.zone_streets).to be_empty
  end
end

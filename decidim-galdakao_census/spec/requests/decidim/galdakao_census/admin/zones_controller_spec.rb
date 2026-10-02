# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::ZonesController do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:routes) { Decidim::GaldakaoCensus::AdminEngine.routes.url_helpers }
  let(:other_zone) { create(:census_zone, organization: create(:organization)) }

  before do
    host! organization.host
    sign_in create(:user, :admin, :confirmed, organization:)
  end

  def expect_rendered_page
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation_missing")
    expect(response.body).not_to match(/translation missing/i)
  end

  describe "pages" do
    let(:zone) { create(:census_zone, organization:, name: "Zona Centro") }

    before { create(:census_zone_street, zone:, organization:, numbers_constraint: :only_range, numbers_range: "1-9") }

    it "renders the list" do
      get routes.zones_path

      expect_rendered_page
      expect(response.body).to include("Zona Centro")
    end

    it "renders the zone with its streets" do
      get routes.zone_path(zone)

      expect_rendered_page
      expect(response.body).to include("1-9")
    end

    it "renders the new and edit forms" do
      get routes.new_zone_path
      expect_rendered_page

      get routes.edit_zone_path(zone)
      expect_rendered_page
      expect(response.body).to include("Zona Centro")
    end
  end

  describe "pagination" do
    before { create_list(:census_zone, 30, organization:) }

    def listed_zones(params = {})
      get(routes.zones_path, params:)
      Nokogiri::HTML(response.body).css("#census-zones tbody tr").size
    end

    it "shows the Decidim default number of zones per page" do
      expect(listed_zones).to eq(Decidim::Paginable::OPTIONS.first)
    end

    it "respects the number of zones per page chosen by the user" do
      expect(listed_zones(per_page: 50)).to eq(30)
    end
  end

  describe "create, update and destroy" do
    it "creates a zone and registers it in the admin log" do
      expect { post routes.zones_path, params: { zone: { name: "Nueva" } } }
        .to change(Decidim::GaldakaoCensus::Zone, :count).by(1)
        .and change(Decidim::ActionLog, :count).by(1)

      expect(response).to redirect_to(routes.zones_path)
    end

    it "renders the form with an error status when the zone is not valid" do
      post routes.zones_path, params: { zone: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).not_to include("translation_missing")
    end

    it "updates a zone" do
      zone = create(:census_zone, organization:)

      patch routes.zone_path(zone), params: { zone: { name: "Renombrada" } }

      expect(zone.reload.name).to eq("Renombrada")
    end

    it "destroys a zone and registers it in the admin log" do
      zone = create(:census_zone, organization:)

      expect { delete routes.zone_path(zone) }.to change(Decidim::ActionLog, :count).by(1)
      expect(Decidim::GaldakaoCensus::Zone.exists?(zone.id)).to be(false)
    end
  end

  context "when the user is not an admin" do
    before do
      sign_out :user
      sign_in create(:user, :confirmed, organization:)
    end

    it "does not show the zones" do
      get routes.zones_path

      expect(response).to have_http_status(:redirect)
    end

    it "does not create zones" do
      expect { post routes.zones_path, params: { zone: { name: "Nueva" } } }
        .not_to change(Decidim::GaldakaoCensus::Zone, :count)
    end
  end

  describe "zones JSON used by the permissions selector" do
    let!(:zones) { create_list(:census_zone, 55, organization:) }

    def json_zone_ids(params)
      get routes.zones_path(format: :json), params: params
      response.parsed_body.pluck("id")
    end

    it "returns every zone of the organization, not only the first page" do
      expect(json_zone_ids(q: "").size).to eq(55)
    end

    it "finds a zone by id beyond the first page" do
      last_zone = zones.max_by(&:name)

      expect(json_zone_ids(ids: last_zone.id.to_s)).to eq([last_zone.id])
    end

    it "does not return zones of other organizations" do
      other_zone = create(:census_zone)

      expect(json_zone_ids(q: "")).not_to include(other_zone.id)
    end

    it "treats SQL wildcards in the search as plain text" do
      expect(json_zone_ids(q: "%")).to be_empty
    end
  end

  context "when the zone belongs to another organization" do
    it "does not show the zone" do
      get routes.zone_path(other_zone)

      expect(response).to have_http_status(:not_found)
    end

    it "does not destroy the zone" do
      delete routes.zone_path(other_zone)

      expect(response).to have_http_status(:not_found)
      expect(Decidim::GaldakaoCensus::Zone.exists?(other_zone.id)).to be(true)
    end

    it "does not show the form to add streets to the zone" do
      get routes.new_zone_zone_street_path(other_zone)

      expect(response).to have_http_status(:not_found)
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::StreetsController do
  include Devise::Test::IntegrationHelpers

  let(:organization) { create(:organization) }
  let(:routes) { Decidim::GaldakaoCensus::AdminEngine.routes.url_helpers }

  before do
    host! organization.host
    sign_in create(:user, :admin, :confirmed, organization:)
  end

  it "renders the management panel with the sync button and the link to the list" do
    get routes.manage_streets_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation_missing")
    expect(response.body).to include(routes.sync_streets_path)
    expect(response.body).to include(%(href="#{routes.streets_path}"))
  end

  it "shows a message when there are no streets yet" do
    get routes.streets_path

    expect(response.body).to include(I18n.t("decidim.galdakao_census.admin.streets.index.no_streets"))
  end

  it "renders the list of streets" do
    create(:census_street, organization:, name: "Kale Nagusia")

    get routes.streets_path

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("translation_missing")
    expect(response.body).to include("Kale Nagusia")
  end

  describe "pagination" do
    before { create_list(:census_street, 30, organization:) }

    def listed_streets(params = {})
      get(routes.streets_path, params:)
      Nokogiri::HTML(response.body).css("#census-streets tbody tr").size
    end

    it "shows the Decidim default number of streets per page" do
      expect(listed_streets).to eq(Decidim::Paginable::OPTIONS.first)
    end

    it "respects the number of streets per page chosen by the user" do
      expect(listed_streets(per_page: 50)).to eq(30)
    end
  end

  it "shows the most recent sync, not the oldest street" do
    create(:census_street, organization:, updated_at: 1.month.ago)
    create(:census_street, organization:, updated_at: 1.hour.ago)

    get routes.manage_streets_path

    expect(response.body).to include("callout success")
  end

  describe "sync" do
    context "when the municipal register service is unavailable" do
      before { allow(Decidim::GaldakaoCensus::Street).to receive(:import_streets).and_return(nil) }

      it "redirects to the panel with an error message instead of failing" do
        post routes.sync_streets_path

        expect(response).to redirect_to(routes.manage_streets_path)
        expect(flash[:alert]).to eq(I18n.t("decidim.galdakao_census.admin.streets.sync.error"))
      end
    end

    context "when the service returns the streets" do
      before { allow(Decidim::GaldakaoCensus::Street).to receive(:import_streets).and_return(["Kale Nagusia"]) }

      it "imports them and redirects to the streets list" do
        post routes.sync_streets_path

        expect(response).to redirect_to(routes.streets_path)
        expect(flash[:notice]).to eq(I18n.t("decidim.galdakao_census.admin.streets.sync.success"))
        expect(Decidim::GaldakaoCensus::Street.where(organization:).pluck(:name)).to eq(["Kale Nagusia"])
      end
    end
  end

  it "does not expose the removed check action" do
    expect(routes).not_to respond_to(:check_galdakao_index_path)
  end
end

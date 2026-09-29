# frozen_string_literal: true

require "rails_helper"

describe "Admin census menu" do # rubocop:disable RSpec/DescribeClass
  let(:organization) { create(:organization, available_authorizations: ["census_authorization_handler"]) }

  before do
    test_webservice = instance_double(Decidim::GaldakaoCensus::Webservice, response: nil)
    allow(Decidim::GaldakaoCensus::Webservice).to receive(:new).with("TestDBconnection").and_return(test_webservice)
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  context "when the user is an admin" do
    let(:user) { create(:user, :admin, :confirmed, organization:) }

    it "shows the census entry in the main menu and navigates its secondary menu" do
      visit decidim_admin.root_path

      within ".layout-nav" do
        click_on "Galdakao census"
      end

      expect(page).to have_current_path("/admin/galdakao_census/connection")

      within ".sidebar-menu" do
        expect(page).to have_content("Webservice Sync")
        expect(page).to have_link("Check")
        expect(page).to have_link("Streets")
        expect(page).to have_link("Blocked authorizations")
        click_on "Zones"
      end

      expect(page).to have_current_path("/admin/galdakao_census/zones")
      expect(page).to have_css(".layout-nav .is-active", text: "Galdakao census")
    end
  end

  context "when the user is not an admin" do
    let(:user) { create(:user, :confirmed, organization:) }
    let(:participatory_process) { create(:participatory_process, organization:) }

    before do
      create(:participatory_process_user_role, user:, participatory_process:, role: :admin)
    end

    it "does not show the census entry" do
      visit decidim_admin.root_path

      expect(page).to have_no_link("Galdakao census")
    end
  end
end

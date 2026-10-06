# frozen_string_literal: true

require "rails_helper"

describe "Admin goes back to the impersonation form with several authorization methods" do # rubocop:disable RSpec/DescribeClass
  let(:organization) { create(:organization, available_authorizations: %w(file_authorization_handler census_authorization_handler)) }
  let(:admin) { create(:user, :admin, :confirmed, :admin_terms_accepted, organization:) }

  before do
    switch_to_host(organization.host)
    login_as admin, scope: :user
    visit decidim_admin.new_impersonatable_user_impersonation_path(impersonatable_user_id: "new_managed_user")

    # The browser restores the selected method without firing "change"
    page.execute_script(<<~JS)
      document.getElementById("impersonate_user_authorization_handler_name").value = "census_authorization_handler";
      window.dispatchEvent(new PageTransitionEvent("pageshow", { persisted: false }));
    JS
  end

  it "shows the form of the selected method" do
    expect(page).to have_css("#authorization-handler-census_authorization_handler", visible: :visible)
    expect(page).to have_css("#authorization-handler-file_authorization_handler", visible: :hidden)
    expect(page).to have_field("impersonate_user[authorization][handler_name]", type: :hidden, with: "census_authorization_handler")
  end
end

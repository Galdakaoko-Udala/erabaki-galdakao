# frozen_string_literal: true

require "rails_helper"

describe "Admin impersonates a new managed user with the census" do # rubocop:disable RSpec/DescribeClass
  let(:organization) { create(:organization, available_authorizations: ["census_authorization_handler"]) }
  let(:admin) { create(:user, :admin, :confirmed, :admin_terms_accepted, organization:) }
  let(:authenticated) { "true" }

  before do
    allow(Decidim::GaldakaoCensus::Webservice).to receive(:authenticate).and_return(Nokogiri::XML(<<~XML))
      <Envelope><Body><autenticarResponse><autenticarResult>
        <autenticarResult>#{authenticated}</autenticarResult><calle>Kale Nagusia</calle><portal>4</portal>
      </autenticarResult></autenticarResponse></Body></Envelope>
    XML
    switch_to_host(organization.host)
    login_as admin, scope: :user
    visit decidim_admin.new_impersonatable_user_impersonation_path(impersonatable_user_id: "new_managed_user")

    within "form.new_impersonation" do
      fill_in :impersonate_user_name, with: "Rigoberto"
      fill_in :census_authorization_handler_document_number, with: "12345678z"
      fill_in_datepicker :census_authorization_handler_date_of_birth_date, with: "01/01/1980"
    end
    within("[data-content]") { click_on "Impersonate" }
  end

  it "creates the managed user with a census authorization and impersonates it" do
    expect(page).to have_content("successfully")

    managed_user = Decidim::User.managed.find_by(name: "Rigoberto")
    expect(Decidim::Authorization.where(user: managed_user).pluck(:name)).to eq(["census_authorization_handler"])
    expect(managed_user.extended_data.dig("authorizations", "census_authorization_handler")).to be_nil
  end

  context "when the document is not in the census" do
    let(:authenticated) { "false" }

    it "shows the error in the form without creating the user" do
      expect(page).to have_content("The data entered is not in the Galdakao municipal register.")
      expect(Decidim::User.managed.where(name: "Rigoberto")).to be_empty
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

describe "Admin checks the census connection" do # rubocop:disable RSpec/DescribeClass
  let(:organization) { create(:organization, available_authorizations: ["census_authorization_handler"]) }
  let(:admin) { create(:user, :admin, :confirmed, organization:) }
  let(:test_webservice) { instance_double(Decidim::GaldakaoCensus::Webservice, response: test_response) }
  let(:test_response) do
    Nokogiri::XML(<<~XML)
      <Envelope><Body><TestDBconnectionResponse><estado>La conexión se realizó correctamente</estado></TestDBconnectionResponse></Body></Envelope>
    XML
  end
  let(:streets_webservice) { instance_double(Decidim::GaldakaoCensus::Webservice, response: streets_response) }
  let(:streets_response) do
    Nokogiri::XML(<<~XML)
      <Envelope><Body><ListadoCallesResponse><calles><Calle>Kale Nagusia</Calle></calles></ListadoCallesResponse></Body></Envelope>
    XML
  end

  before do
    allow(Decidim::GaldakaoCensus::Webservice).to receive(:new).with("TestDBconnection").and_return(test_webservice)
    allow(Decidim::GaldakaoCensus::Webservice).to receive(:new).with("ListadoCalles").and_return(streets_webservice)
    switch_to_host(organization.host)
    login_as admin, scope: :user
    visit "/admin/galdakao_census"
    within(".sidebar-menu") { click_on "Check" }
  end

  it "shows the response of the register to the connection test" do
    expect(page).to have_css("h2", text: "TestDBconnection:")
    expect(page).to have_no_css("#census-connection-fallback")
    within "#census-connection-response" do
      expect(page).to have_content("<TestDBconnectionResponse>")
      expect(page).to have_content("<estado>La conexión se realizó correctamente</estado>")
    end
    expect(Decidim::GaldakaoCensus::Webservice).not_to have_received(:new).with("ListadoCalles")
  end

  context "when the register does not answer the connection test" do
    let(:test_response) { nil }

    it "checks the connection with the street list" do
      expect(page).to have_css("h2", text: "ListadoCalles:")
      expect(page).to have_content("TestDBconnection did not answer, so the connection has been checked with ListadoCalles.")
      within "#census-connection-response" do
        expect(page).to have_content("<Calle>Kale Nagusia</Calle>")
      end
    end
  end

  context "when the service is unavailable" do
    let(:test_response) { nil }
    let(:streets_response) { nil }

    it "reports it" do
      expect(page).to have_content("The municipal register service is not available")
    end
  end

  it "validates a person against the register without creating an authorization" do
    allow(Decidim::GaldakaoCensus::Webservice).to receive(:authenticate).and_return(Nokogiri::XML(<<~XML))
      <Envelope><Body><autenticarResponse><autenticarResult><autenticarResult>true</autenticarResult></autenticarResult></autenticarResponse></Body></Envelope>
    XML

    fill_in "Document number", with: "12345678Z"
    fill_in_datepicker :census_check_date_of_birth_date, with: "01/01/1980"
    click_on "Validate ID"

    within "#census-check-response" do
      expect(page).to have_content("<autenticarResult>true</autenticarResult>")
    end
    expect(Decidim::Authorization.count).to eq(0)
  end
end

# frozen_string_literal: true

require "rails_helper"

describe "Admin manages census zones" do # rubocop:disable RSpec/DescribeClass
  let(:organization) { create(:organization, available_authorizations: ["census_authorization_handler"]) }
  let(:admin) { create(:user, :admin, :confirmed, organization:) }
  let!(:street) { create(:census_street, organization:, name: "Kale Nagusia") }

  before do
    switch_to_host(organization.host)
    login_as admin, scope: :user
  end

  it "creates a zone and adds a street restricted to a range of portals" do
    visit "/admin/galdakao_census/zones"
    click_on "New zone"

    fill_in "Zone name", with: "Zona Centro"
    click_on "Save"

    expect(page).to have_content("New zone created successfully")
    click_on "Zona Centro"
    click_on "Add street"

    select "Kale Nagusia", from: "Street"
    expect(page).to have_no_field("Doorways")

    select "Only these portals", from: "Number constraint"
    expect(page).to have_field("Doorways")

    select "All numbers", from: "Number constraint"
    expect(page).to have_no_field("Doorways")

    select "Only these portals", from: "Number constraint"
    fill_in "Doorways", with: "1-20"
    click_on "Save"

    expect(page).to have_content("Street added successfully")
    within "tr", text: "Kale Nagusia" do
      expect(page).to have_content("Only these portals")
      expect(page).to have_content("1-20")
    end
  end

  it "removes a street from a zone from the actions menu" do
    zone = create(:census_zone, organization:, name: "Zona Centro")
    create(:census_zone_street, zone:, street:, organization:)

    visit "/admin/galdakao_census/zones/#{zone.id}"

    within "tr", text: "Kale Nagusia" do
      find("button[data-controller='dropdown']").click
      accept_confirm { click_on "Delete" }
    end

    expect(page).to have_content("Street removed successfully")
    expect(page).to have_content("This zone has no streets yet.")
  end
end

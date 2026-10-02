# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Zone do
  describe "associations" do
    it "belongs to an organization" do
      zone = create(:census_zone)

      expect(zone.organization).to be_a(Decidim::Organization)
    end

    it "has many zone_streets" do
      zone = create(:census_zone)
      first_zone_street = create(:census_zone_street, zone:)
      second_zone_street = create(:census_zone_street, zone:)

      expect(zone.zone_streets).to contain_exactly(first_zone_street, second_zone_street)
    end

    it "destroys associated zone_streets when destroyed" do
      zone = create(:census_zone)
      create(:census_zone_street, zone:)

      expect { zone.destroy }.to change(Decidim::GaldakaoCensus::ZoneStreet, :count).by(-1)
    end

    it "has many streets through zone_streets" do
      zone = create(:census_zone)
      street = create(:census_street, organization: zone.organization)
      create(:census_zone_street, zone:, street:)

      expect(zone.streets).to contain_exactly(street)
    end

    it "does not list a street that is not linked through a zone_street" do
      zone = create(:census_zone)
      create(:census_street, organization: zone.organization)

      expect(zone.streets).to be_empty
    end
  end

  describe "validations" do
    it "is valid with a name" do
      zone = build(:census_zone, name: "Zona Centro")

      expect(zone).to be_valid
    end

    it "is not valid without a name" do
      zone = build(:census_zone, name: nil)

      expect(zone).not_to be_valid
    end
  end
end

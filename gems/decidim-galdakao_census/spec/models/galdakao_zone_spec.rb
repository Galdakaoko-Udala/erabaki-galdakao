# frozen_string_literal: true

require "rails_helper"

describe GaldakaoZone do
  describe "associations" do
    it "belongs to an organization" do
      zone = create(:galdakao_zone)

      expect(zone.organization).to be_a(Decidim::Organization)
    end

    it "has many zone_streets" do
      zone = create(:galdakao_zone)
      zone_street_1 = create(:galdakao_zone_street, zone:)
      zone_street_2 = create(:galdakao_zone_street, zone:)

      expect(zone.zone_streets).to contain_exactly(zone_street_1, zone_street_2)
    end

    it "destroys associated zone_streets when destroyed" do
      zone = create(:galdakao_zone)
      create(:galdakao_zone_street, zone:)

      expect { zone.destroy }.to change(GaldakaoZoneStreet, :count).by(-1)
    end

    it "has many streets through zone_streets" do
      zone = create(:galdakao_zone)
      street = create(:galdakao_street, organization: zone.organization)
      create(:galdakao_zone_street, zone:, street:)

      expect(zone.streets).to contain_exactly(street)
    end

    it "does not list a street that is not linked through a zone_street" do
      zone = create(:galdakao_zone)
      create(:galdakao_street, organization: zone.organization)

      expect(zone.streets).to be_empty
    end
  end

  describe "validations" do
    it "is valid with a name" do
      zone = build(:galdakao_zone, name: "Zona Centro")

      expect(zone).to be_valid
    end

    it "is not valid without a name" do
      zone = build(:galdakao_zone, name: nil)

      expect(zone).not_to be_valid
    end
  end
end
# frozen_string_literal: true

require "rails_helper"

RSpec.describe GaldakaoZone, type: :model do
  subject(:zone) { build(:galdakao_zone) }

  it { is_expected.to be_valid }

  describe "validations" do
    it "requires a name" do
      zone.name = nil
      expect(zone).not_to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:organization).class_name("Decidim::Organization") }
    it { is_expected.to have_many(:zone_streets).class_name("GaldakaoZoneStreet").dependent(:destroy) }
    it { is_expected.to have_many(:streets).class_name("GaldakaoStreet").through(:zone_streets) }
  end
end
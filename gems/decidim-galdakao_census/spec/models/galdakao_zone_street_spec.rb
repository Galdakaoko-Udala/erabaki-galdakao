# frozen_string_literal: true

require "rails_helper"

RSpec.describe GaldakaoZoneStreet, type: :model do
  subject(:zone_street) { build(:galdakao_zone_street) }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:zone).class_name("GaldakaoZone") }
    it { is_expected.to belong_to(:street).class_name("GaldakaoStreet") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:numbers_constraint) }

    context "when numbers_constraint requires a range" do
      subject(:zone_street) { build(:galdakao_zone_street, :only_range, numbers_range: nil) }

      it "requires numbers_range to be present" do
        expect(zone_street).not_to be_valid
        expect(zone_street.errors[:numbers_range]).to be_present
      end
    end

    context "when numbers_constraint does not require a range" do
      subject(:zone_street) { build(:galdakao_zone_street, numbers_constraint: :all_numbers, numbers_range: nil) }

      it "does not require numbers_range" do
        expect(zone_street).to be_valid
      end
    end

    context "when numbers_range has a valid format" do
      subject(:zone_street) { build(:galdakao_zone_street, :only_range, numbers_range: "1-10,15,20-25") }

      it { is_expected.to be_valid }
    end

    context "when numbers_range has an invalid format" do
      subject(:zone_street) { build(:galdakao_zone_street, :only_range, numbers_range: "abc") }

      it { is_expected.not_to be_valid }
    end
  end

  describe "enum numbers_constraint" do
    it "defines the expected values" do
      expect(described_class.numbers_constraints).to eq(
        "all_numbers" => 0,
        "odd_numbers" => 1,
        "even_numbers" => 2,
        "only_range" => 3,
        "except_range" => 4
      )
    end
  end
end
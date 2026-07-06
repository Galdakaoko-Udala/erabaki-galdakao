# frozen_string_literal: true

require "rails_helper"

describe GaldakaoZoneStreet do
  describe "associations" do
    it "belongs to a zone" do
      zone_street = create(:galdakao_zone_street)

      expect(zone_street.zone).to be_a(GaldakaoZone)
    end

    it "belongs to a street" do
      zone_street = create(:galdakao_zone_street)

      expect(zone_street.street).to be_a(GaldakaoStreet)
    end
  end

  describe "numbers_constraint enum" do
    it "exposes the expected constraint values" do
      expect(described_class.numbers_constraints).to eq(
        "all_numbers" => 0,
        "odd_numbers" => 1,
        "even_numbers" => 2,
        "only_range" => 3,
        "except_range" => 4
      )
    end
  end

  describe "validations" do
    it "is not valid without a zone" do
      zone_street = build(:galdakao_zone_street, zone: nil)

      expect(zone_street).not_to be_valid
    end

    it "is not valid without a street" do
      zone_street = build(:galdakao_zone_street, street: nil)

      expect(zone_street).not_to be_valid
    end

    it "is not valid without a numbers_constraint" do
      zone_street = build(:galdakao_zone_street, numbers_constraint: nil)

      expect(zone_street).not_to be_valid
    end

    context "when numbers_constraint does not require a range" do
      it "is valid without a numbers_range" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :all_numbers, numbers_range: nil)

        expect(zone_street).to be_valid
      end
    end

    context "when numbers_constraint is only_range" do
      it "is not valid without a numbers_range" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :only_range, numbers_range: nil)

        expect(zone_street).not_to be_valid
      end

      it "is valid with a numbers_range" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :only_range, numbers_range: "1-10")

        expect(zone_street).to be_valid
      end
    end

    context "when numbers_constraint is except_range" do
      it "is not valid without a numbers_range" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :except_range, numbers_range: nil)

        expect(zone_street).not_to be_valid
      end
    end

    context "numbers_range format" do
      it "is valid with a single number" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :only_range, numbers_range: "4")

        expect(zone_street).to be_valid
      end

      it "is valid with a simple range" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :only_range, numbers_range: "1-10")

        expect(zone_street).to be_valid
      end

      it "is valid with a comma separated list of numbers and ranges" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :only_range, numbers_range: "1-4,7,10-12")

        expect(zone_street).to be_valid
      end

      it "is not valid with letters" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :only_range, numbers_range: "abc")

        expect(zone_street).not_to be_valid
      end

      it "is not valid with a trailing separator" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :only_range, numbers_range: "1-4,")

        expect(zone_street).not_to be_valid
      end

      it "is not valid with a malformed range" do
        zone_street = build(:galdakao_zone_street, numbers_constraint: :only_range, numbers_range: "1--4")

        expect(zone_street).not_to be_valid
      end
    end
  end
end
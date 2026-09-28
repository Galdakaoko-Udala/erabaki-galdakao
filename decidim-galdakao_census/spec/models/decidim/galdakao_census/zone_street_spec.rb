# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::ZoneStreet do
  describe "associations" do
    it "belongs to a zone" do
      zone_street = create(:census_zone_street)

      expect(zone_street.zone).to be_a(Decidim::GaldakaoCensus::Zone)
    end

    it "belongs to a street" do
      zone_street = create(:census_zone_street)

      expect(zone_street.street).to be_a(Decidim::GaldakaoCensus::Street)
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
      zone_street = build(:census_zone_street, zone: nil)

      expect(zone_street).not_to be_valid
    end

    it "is not valid without a street" do
      zone_street = build(:census_zone_street, street: nil)

      expect(zone_street).not_to be_valid
    end

    it "is not valid without a numbers_constraint" do
      zone_street = build(:census_zone_street, numbers_constraint: nil)

      expect(zone_street).not_to be_valid
    end

    context "when numbers_constraint does not require a range" do
      it "is valid without a numbers_range" do
        zone_street = build(:census_zone_street, numbers_constraint: :all_numbers, numbers_range: nil)

        expect(zone_street).to be_valid
      end
    end

    context "when numbers_constraint is only_range" do
      it "is not valid without a numbers_range" do
        zone_street = build(:census_zone_street, numbers_constraint: :only_range, numbers_range: nil)

        expect(zone_street).not_to be_valid
      end

      it "is valid with a numbers_range" do
        zone_street = build(:census_zone_street, numbers_constraint: :only_range, numbers_range: "1-10")

        expect(zone_street).to be_valid
      end
    end

    context "when numbers_constraint is except_range" do
      it "is not valid without a numbers_range" do
        zone_street = build(:census_zone_street, numbers_constraint: :except_range, numbers_range: nil)

        expect(zone_street).not_to be_valid
      end
    end

    context "with a numbers_range format" do
      it "is valid with a single number" do
        zone_street = build(:census_zone_street, numbers_constraint: :only_range, numbers_range: "4")

        expect(zone_street).to be_valid
      end

      it "is valid with a simple range" do
        zone_street = build(:census_zone_street, numbers_constraint: :only_range, numbers_range: "1-10")

        expect(zone_street).to be_valid
      end

      it "is valid with a comma separated list of numbers and ranges" do
        zone_street = build(:census_zone_street, numbers_constraint: :only_range, numbers_range: "1-4,7,10-12")

        expect(zone_street).to be_valid
      end

      it "is not valid with letters" do
        zone_street = build(:census_zone_street, numbers_constraint: :only_range, numbers_range: "abc")

        expect(zone_street).not_to be_valid
      end

      it "is not valid with a trailing separator" do
        zone_street = build(:census_zone_street, numbers_constraint: :only_range, numbers_range: "1-4,")

        expect(zone_street).not_to be_valid
      end

      it "is not valid with a malformed range" do
        zone_street = build(:census_zone_street, numbers_constraint: :only_range, numbers_range: "1--4")

        expect(zone_street).not_to be_valid
      end
    end
  end

  describe "#allows_number?" do
    def zone_street(constraint, range = nil)
      build(:census_zone_street, numbers_constraint: constraint, numbers_range: range)
    end

    it "allows every number with all_numbers" do
      expect(zone_street(:all_numbers).allows_number?(7)).to be(true)
    end

    it "checks the parity" do
      expect(zone_street(:even_numbers).allows_number?(4)).to be(true)
      expect(zone_street(:even_numbers).allows_number?(5)).to be(false)
      expect(zone_street(:odd_numbers).allows_number?(5)).to be(true)
      expect(zone_street(:odd_numbers).allows_number?(4)).to be(false)
    end

    it "checks ranges and single numbers with only_range" do
      street = zone_street(:only_range, "1-10,15")

      expect([1, 10, 15].map { |n| street.allows_number?(n) }).to all(be(true))
      expect([0, 11, 14, 16].map { |n| street.allows_number?(n) }).to all(be(false))
    end

    it "excludes ranges with except_range" do
      street = zone_street(:except_range, "1-10")

      expect(street.allows_number?(5)).to be(false)
      expect(street.allows_number?(11)).to be(true)
    end

    it "handles large ranges without expanding them" do
      expect(zone_street(:only_range, "1-100000000").allows_number?(99_999_999)).to be(true)
    end
  end
end

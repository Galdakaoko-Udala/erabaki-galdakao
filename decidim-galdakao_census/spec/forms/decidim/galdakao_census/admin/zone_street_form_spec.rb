# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::ZoneStreetForm do
  subject(:form) do
    described_class.new(street_id:, numbers_constraint:, numbers_range:)
                   .with_context(current_organization: organization)
  end

  let(:organization) { create(:organization) }
  let(:street_id) { create(:census_street, organization:).id }
  let(:numbers_constraint) { "all_numbers" }
  let(:numbers_range) { nil }

  describe "defaults" do
    it "defaults numbers_constraint to all_numbers when not given" do
      default_form = described_class.new(street_id:)

      expect(default_form.numbers_constraint).to eq("all_numbers")
    end
  end

  describe "validations" do
    context "when the street belongs to another organization" do
      let(:street_id) { create(:census_street).id }

      it "is not valid" do
        expect(form).not_to be_valid
        expect(form.errors[:street_id]).to be_present
      end
    end

    it "is not valid without a street_id" do
      form.street_id = nil

      expect(form).not_to be_valid
    end

    it "is not valid without a numbers_constraint" do
      form.numbers_constraint = nil

      expect(form).not_to be_valid
    end

    context "when numbers_constraint does not require a range" do
      it "is valid without a numbers_range" do
        expect(form).to be_valid
      end
    end

    context "when numbers_constraint is only_range" do
      let(:numbers_constraint) { "only_range" }

      it "is not valid without a numbers_range" do
        expect(form).not_to be_valid
      end

      it "is valid with a numbers_range" do
        form.numbers_range = "1-10"

        expect(form).to be_valid
      end
    end

    context "when numbers_constraint is except_range" do
      let(:numbers_constraint) { "except_range" }

      it "is not valid without a numbers_range" do
        expect(form).not_to be_valid
      end
    end

    context "with a numbers_range format" do
      let(:numbers_constraint) { "only_range" }

      it "is valid with a single number" do
        form.numbers_range = "4"

        expect(form).to be_valid
      end

      it "is valid with a simple range" do
        form.numbers_range = "1-10"

        expect(form).to be_valid
      end

      it "is valid with a comma separated list of numbers and ranges" do
        form.numbers_range = "1-4,7,10-12"

        expect(form).to be_valid
      end

      it "is not valid with letters" do
        form.numbers_range = "abc"

        expect(form).not_to be_valid
      end

      it "is not valid with a malformed range" do
        form.numbers_range = "1--4"

        expect(form).not_to be_valid
      end

      it "is valid with a range whose bounds are equal" do
        form.numbers_range = "5-5"

        expect(form).to be_valid
      end

      it "is not valid with a descending range" do
        form.numbers_range = "10-1"

        expect(form).not_to be_valid
      end

      it "is not valid when any segment is a descending range" do
        form.numbers_range = "1-4,10-5"

        expect(form).not_to be_valid
      end
    end
  end

  describe "#numbers_constraint_options" do
    it "returns every constraint value with its translated label" do
      scope = "decidim.galdakao_census.numbers_constraints"

      expect(form.numbers_constraint_options).to eq(
        %w(all_numbers odd_numbers even_numbers only_range except_range).map { |value| [I18n.t(value, scope:), value] }
      )
    end
  end
end

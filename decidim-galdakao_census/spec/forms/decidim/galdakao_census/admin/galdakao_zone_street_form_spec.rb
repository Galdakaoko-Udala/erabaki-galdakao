# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::GaldakaoZoneStreetForm do
  subject(:form) { described_class.new(street_id:, numbers_constraint:, numbers_range:) }

  let(:street_id) { create(:galdakao_street).id }
  let(:numbers_constraint) { "all_numbers" }
  let(:numbers_range) { nil }

  describe "defaults" do
    it "defaults numbers_constraint to all_numbers when not given" do
      default_form = described_class.new(street_id:)

      expect(default_form.numbers_constraint).to eq("all_numbers")
    end
  end

  describe "validations" do
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
    end
  end

  describe "#numbers_constraint_options" do
    it "returns every constraint value with its translated label" do
      base = "decidim.admin.galdakao.zone_streets.form.numbers_constraint_options"

      expect(form.numbers_constraint_options).to eq(
        I18n.t("#{base}.all_numbers") => "all_numbers",
        I18n.t("#{base}.even_numbers") => "even_numbers",
        I18n.t("#{base}.odd_numbers") => "odd_numbers",
        I18n.t("#{base}.only_range") => "only_range",
        I18n.t("#{base}.except_range") => "except_range"
      )
    end
  end
end

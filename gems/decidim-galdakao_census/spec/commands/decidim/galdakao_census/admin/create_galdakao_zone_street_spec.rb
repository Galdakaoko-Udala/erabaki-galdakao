# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::CreateGaldakaoZoneStreet do
  subject(:command) { described_class.new(form, zone) }

  let(:organization) { create(:organization) }
  let(:zone) { create(:galdakao_zone, organization:) }
  let(:street) { create(:galdakao_street, organization:) }
  let(:form) do
    Decidim::GaldakaoCensus::Admin::GaldakaoZoneStreetForm
      .from_params(street_id:, numbers_constraint:, numbers_range:)
      .with_context(current_organization: organization)
  end
  let(:street_id) { street.id }
  let(:numbers_constraint) { "all_numbers" }
  let(:numbers_range) { nil }

  context "when the form is not valid" do
    let(:street_id) { nil }

    it "broadcasts invalid" do
      expect { command.call }.to broadcast(:invalid)
    end

    it "does not create a zone_street" do
      expect { command.call }.not_to change(GaldakaoZoneStreet, :count)
    end
  end

  context "when the form is valid" do
    it "broadcasts ok" do
      expect { command.call }.to broadcast(:ok)
    end

    it "creates a zone_street linked to the given zone" do
      command.call

      zone_street = GaldakaoZoneStreet.last
      expect(zone_street.zone).to eq(zone)
      expect(zone_street.street_id).to eq(street.id)
    end

    context "when the constraint requires a range" do
      let(:numbers_constraint) { "only_range" }
      let(:numbers_range) { "1-10" }

      it "persists the numbers_range" do
        command.call

        expect(GaldakaoZoneStreet.last.numbers_range).to eq("1-10")
      end
    end

    context "when the constraint does not require a range" do
      let(:numbers_constraint) { "all_numbers" }
      let(:numbers_range) { nil }

      it "does not persist a numbers_range" do
        command.call

        expect(GaldakaoZoneStreet.last.numbers_range).to be_nil
      end
    end
  end

  context "when persisting the zone_street fails" do
    before do
      allow(GaldakaoZoneStreet).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(GaldakaoZoneStreet.new))
    end

    it "broadcasts invalid" do
      expect { command.call }.to broadcast(:invalid)
    end
  end
end
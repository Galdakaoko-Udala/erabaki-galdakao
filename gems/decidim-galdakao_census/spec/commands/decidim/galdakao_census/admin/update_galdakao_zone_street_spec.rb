# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::UpdateGaldakaoZoneStreet do
  subject(:command) { described_class.new(form, zone_street) }

  let(:organization) { create(:organization) }
  let(:zone) { create(:galdakao_zone, organization:) }
  let(:street) { create(:galdakao_street, organization:) }
  let(:other_street) { create(:galdakao_street, organization:) }
  let(:zone_street) do
    create(:galdakao_zone_street, zone:, street:, numbers_constraint: "all_numbers", numbers_range: nil)
  end
  let(:form) do
    Decidim::GaldakaoCensus::Admin::GaldakaoZoneStreetForm
      .from_params(street_id:, numbers_constraint:, numbers_range:)
      .with_context(current_organization: organization)
  end
  let(:street_id) { other_street.id }
  let(:numbers_constraint) { "all_numbers" }
  let(:numbers_range) { nil }

  context "when the form is not valid" do
    let(:street_id) { nil }

    it "broadcasts invalid" do
      expect { command.call }.to broadcast(:invalid)
    end

    it "does not update the zone_street" do
      expect { command.call }.not_to(change { zone_street.reload.street_id })
    end
  end

  context "when the form is valid" do
    it "broadcasts ok" do
      expect { command.call }.to broadcast(:ok)
    end

    it "updates the street_id and numbers_constraint" do
      command.call

      zone_street.reload
      expect(zone_street.street_id).to eq(other_street.id)
      expect(zone_street.numbers_constraint).to eq("all_numbers")
    end

    context "when the new constraint requires a range" do
      let(:numbers_constraint) { "only_range" }
      let(:numbers_range) { "1-10" }

      it "persists the numbers_range" do
        command.call

        expect(zone_street.reload.numbers_range).to eq("1-10")
      end
    end

    context "when the new constraint does not require a range" do
      before do
        zone_street.update!(numbers_constraint: "only_range", numbers_range: "5-9")
      end

      it "clears the previously stored numbers_range" do
        command.call

        expect(zone_street.reload.numbers_range).to be_nil
      end
    end
  end

  context "when persisting the update fails" do
    before do
      allow(zone_street).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(zone_street))
    end

    it "broadcasts invalid" do
      expect { command.call }.to broadcast(:invalid)
    end
  end
end
# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::CreateZoneStreet do
  subject(:command) { described_class.new(form) }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:zone) { create(:census_zone, organization:) }
  let(:street) { create(:census_street, organization:) }
  let(:form) do
    Decidim::GaldakaoCensus::Admin::ZoneStreetForm
      .from_params(street_id:, numbers_constraint:, numbers_range:)
      .with_context(current_organization: organization, current_user: user, zone:)
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
      expect { command.call }.not_to change(Decidim::GaldakaoCensus::ZoneStreet, :count)
    end
  end

  context "when the form is valid" do
    it "broadcasts ok" do
      expect { command.call }.to broadcast(:ok)
    end

    it "registers the action in the admin log" do
      expect { command.call }.to change(Decidim::ActionLog, :count).by(1)
      expect(Decidim::ActionLog.last.resource).to eq(Decidim::GaldakaoCensus::ZoneStreet.last)
    end

    it "creates a zone_street linked to the given zone" do
      command.call

      zone_street = Decidim::GaldakaoCensus::ZoneStreet.last
      expect(zone_street.zone).to eq(zone)
      expect(zone_street.street_id).to eq(street.id)
    end

    context "when the constraint requires a range" do
      let(:numbers_constraint) { "only_range" }
      let(:numbers_range) { "1-10" }

      it "persists the numbers_range" do
        command.call

        expect(Decidim::GaldakaoCensus::ZoneStreet.last.numbers_range).to eq("1-10")
      end
    end

    context "when the constraint does not require a range" do
      let(:numbers_constraint) { "all_numbers" }
      let(:numbers_range) { "1-10" }

      it "does not persist a numbers_range" do
        command.call

        expect(Decidim::GaldakaoCensus::ZoneStreet.last.numbers_range).to be_nil
      end
    end
  end

  context "when persisting the zone_street fails" do
    before do
      allow(Decidim::GaldakaoCensus::ZoneStreet).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Decidim::GaldakaoCensus::ZoneStreet.new))
    end

    it "broadcasts invalid" do
      expect { command.call }.to broadcast(:invalid)
    end
  end
end

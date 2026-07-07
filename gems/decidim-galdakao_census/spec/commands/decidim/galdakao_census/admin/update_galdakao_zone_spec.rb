# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::UpdateGaldakaoZone do
  subject(:command) { described_class.new(form, zone) }

  let(:organization) { create(:organization) }
  let(:zone) { create(:galdakao_zone, organization:, name: "Old name") }
  let(:form) do
    Decidim::GaldakaoCensus::Admin::GaldakaoZoneForm
      .from_params(name:)
      .with_context(current_organization: organization)
  end
  let(:name) { "New name" }

  context "when the form is not valid" do
    let(:name) { nil }

    it "broadcasts invalid" do
      expect { command.call }.to broadcast(:invalid)
    end

    it "does not update the zone" do
      expect { command.call }.not_to(change { zone.reload.name })
    end
  end

  context "when the form is valid" do
    it "broadcasts ok" do
      expect { command.call }.to broadcast(:ok)
    end

    it "updates the zone's name" do
      command.call

      expect(zone.reload.name).to eq("New name")
    end
  end

  context "when persisting the update fails" do
    before do
      allow(zone).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(zone))
    end

    it "broadcasts invalid" do
      expect { command.call }.to broadcast(:invalid)
    end
  end
end
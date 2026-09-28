# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::CreateZone do
  subject(:command) { described_class.new(form) }

  let(:organization) { create(:organization) }
  let(:form) do
    Decidim::GaldakaoCensus::Admin::ZoneForm
      .from_params(name:)
      .with_context(current_organization: organization)
  end
  let(:name) { "Zona Centro" }

  context "when the form is not valid" do
    let(:name) { nil }

    it "broadcasts invalid" do
      expect { command.call }.to broadcast(:invalid)
    end

    it "does not create a zone" do
      expect { command.call }.not_to change(Decidim::GaldakaoCensus::Zone, :count)
    end
  end

  context "when the form is valid" do
    it "broadcasts ok" do
      expect { command.call }.to broadcast(:ok)
    end

    it "creates a zone belonging to the form's organization" do
      command.call

      zone = Decidim::GaldakaoCensus::Zone.last
      expect(zone.name).to eq(name)
      expect(zone.organization).to eq(organization)
    end
  end

  context "when persisting the zone fails" do
    before do
      allow(Decidim::GaldakaoCensus::Zone).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Decidim::GaldakaoCensus::Zone.new))
    end

    it "broadcasts invalid" do
      expect { command.call }.to broadcast(:invalid)
    end
  end
end

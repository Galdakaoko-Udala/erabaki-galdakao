# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::UserLockedEvent do
  subject(:event) { described_class.new(resource: user, event_name: "decidim.events.galdakao_census.user_locked") }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization:) }

  describe "personal data removal" do
    it "does not expose a resource_path" do
      expect(event.resource_path).to be_nil
    end

    it "does not expose a resource_url" do
      expect(event.resource_url).to be_nil
    end

    it "does not expose a resource_title" do
      expect(event.resource_title).to be_nil
    end
  end

  describe "#default_i18n_options" do
    it "includes the path to the blocked users panel" do
      expect(event.default_i18n_options[:blocked_users_path])
        .to eq("/admin/galdakao_census/galdakao/blocked_users")
    end
  end
end
# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::Permissions do
  subject { described_class.new(user, permission_action, {}).permissions.allowed? }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, :admin, :confirmed, organization:) }
  let(:permission_action) { Decidim::PermissionAction.new(scope: :admin, action:, subject: permission_subject) }
  let(:action) { :read }
  let(:permission_subject) { :census_zone }

  context "when the user is an organization admin" do
    {
      census_street: [:read, :sync],
      census_zone: [:read, :create, :update, :destroy],
      census_zone_street: [:create, :update, :destroy],
      census_blocked_user: [:read, :unlock]
    }.each do |census_subject, actions|
      actions.each do |census_action|
        context "when #{census_action} #{census_subject}" do
          let(:permission_subject) { census_subject }
          let(:action) { census_action }

          it { is_expected.to be(true) }
        end
      end
    end
  end

  context "when the admin has not accepted the admin terms" do
    let(:user) { create(:user, :admin, :confirmed, organization:, admin_terms_accepted_at: nil) }

    it_behaves_like "permission is not set"
  end

  context "when the user is not an admin" do
    let(:user) { create(:user, :confirmed, organization:) }

    it_behaves_like "permission is not set"
  end

  context "when there is no user" do
    let(:user) { nil }

    it_behaves_like "permission is not set"
  end

  context "when the action is not one of the census actions" do
    let(:action) { :publish }

    it_behaves_like "permission is not set"
  end

  context "when the subject belongs to Decidim" do
    let(:permission_subject) { :area }

    it_behaves_like "permission is not set"
  end

  context "when the scope is not admin" do
    let(:permission_action) { Decidim::PermissionAction.new(scope: :public, action:, subject: permission_subject) }

    it_behaves_like "permission is not set"
  end
end

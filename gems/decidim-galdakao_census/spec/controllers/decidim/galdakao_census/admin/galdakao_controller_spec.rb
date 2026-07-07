# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::GaldakaoController do
  subject(:controller_instance) { described_class.new }

  describe "#last_sync_class" do
    context "when datetime is nil" do
      it "returns nil" do
        expect(controller_instance.send(:last_sync_class, nil)).to be_nil
      end
    end

    context "when datetime is more than a week ago" do
      let(:datetime) { 2.weeks.ago }

      it "returns alert" do
        expect(controller_instance.send(:last_sync_class, datetime)).to eq("alert")
      end
    end

    context "when datetime is between a day and a week ago" do
      let(:datetime) { 3.days.ago }

      it "returns warning" do
        expect(controller_instance.send(:last_sync_class, datetime)).to eq("warning")
      end
    end

    context "when datetime is less than a day ago" do
      let(:datetime) { 2.hours.ago }

      it "returns success" do
        expect(controller_instance.send(:last_sync_class, datetime)).to eq("success")
      end
    end
  end
end
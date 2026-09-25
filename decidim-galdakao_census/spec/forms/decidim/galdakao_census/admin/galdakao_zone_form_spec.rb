# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::GaldakaoZoneForm do
  subject(:form) { described_class.new(name:) }

  let(:name) { "Zona Centro" }

  describe "validations" do
    it "is valid with a name" do
      expect(form).to be_valid
    end

    it "is not valid without a name" do
      form.name = nil

      expect(form).not_to be_valid
    end
  end
end

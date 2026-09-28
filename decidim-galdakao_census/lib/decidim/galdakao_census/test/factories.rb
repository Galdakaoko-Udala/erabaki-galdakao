# frozen_string_literal: true

require "decidim/core/test/factories"

FactoryBot.define do
  factory :census_street, class: "Decidim::GaldakaoCensus::Street" do
    organization
    sequence(:name) { |n| "Street #{n}" }
  end

  factory :census_zone, class: "Decidim::GaldakaoCensus::Zone" do
    organization
    sequence(:name) { |n| "Zone #{n}" }
  end

  factory :census_zone_street, class: "Decidim::GaldakaoCensus::ZoneStreet" do
    transient do
      organization { create(:organization) }
    end

    zone { create(:census_zone, organization:) }
    street { create(:census_street, organization:) }
    numbers_constraint { :all_numbers }
    numbers_range { nil }

    trait :only_range do
      numbers_constraint { :only_range }
      numbers_range { "1-50" }
    end

    trait :except_range do
      numbers_constraint { :except_range }
      numbers_range { "1-50" }
    end
  end
end

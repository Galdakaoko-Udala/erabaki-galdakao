# frozen_string_literal: true

require "decidim/core/test/factories"

FactoryBot.define do
  factory :galdakao_street, class: "Decidim::GaldakaoCensus::GaldakaoStreet" do
    organization
    sequence(:name) { |n| "Street #{n}" }
  end

  factory :galdakao_zone, class: "Decidim::GaldakaoCensus::GaldakaoZone" do
    organization
    sequence(:name) { |n| "Zone #{n}" }
  end

  factory :galdakao_zone_street, class: "Decidim::GaldakaoCensus::GaldakaoZoneStreet" do
    transient do
      organization { create(:organization) }
    end

    zone { create(:galdakao_zone, organization:) }
    street { create(:galdakao_street, organization:) }
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

# frozen_string_literal: true

FactoryBot.define do
  factory :galdakao_zone_street, class: "GaldakaoZoneStreet" do
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

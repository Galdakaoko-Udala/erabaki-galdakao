# frozen_string_literal: true

FactoryBot.define do
  factory :galdakao_zone, class: "GaldakaoZone" do
    organization
    sequence(:name) { |n| "Zone #{n}" }
  end
end

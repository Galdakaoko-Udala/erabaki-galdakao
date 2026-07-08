# frozen_string_literal: true

FactoryBot.define do
  factory :galdakao_street, class: "GaldakaoStreet" do
    organization
    sequence(:name) { |n| "Street #{n}" }
  end
end

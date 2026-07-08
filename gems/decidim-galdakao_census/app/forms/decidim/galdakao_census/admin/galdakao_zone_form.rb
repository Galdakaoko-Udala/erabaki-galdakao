# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      class GaldakaoZoneForm < Form
        mimic :galdakao_zone
        attribute :name, String
        validates :name, presence: true
      end
    end
  end
end

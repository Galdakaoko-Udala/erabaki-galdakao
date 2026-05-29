# frozen_string_literal: true
class GaldakaoZone < ApplicationRecord
  belongs_to :organization,
             foreign_key: "decidim_organization_id",
             class_name: "Decidim::Organization"
  has_many :zone_streets,
           class_name: "GaldakaoZoneStreet",
           foreign_key: :zone_id,
           dependent: :destroy
  has_many :streets, through: :zone_streets, class_name: "GaldakaoStreet"

  validates :name, presence: true
end

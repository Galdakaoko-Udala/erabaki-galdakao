# frozen_string_literal: true

class GaldakaoZone < ApplicationRecord
  RANGE_REGEXP = /(\A\d+(-(\d+)*)\z)|(\A[\d+(,\d)*]+\z)/.freeze

  belongs_to :organization,
             foreign_key: "decidim_organization_id",
             class_name: "Decidim::Organization"
  belongs_to :street,
             class_name: "GaldakaoStreet"
  enum numbers_constraint: { all_numbers: 0, odd_numbers: 1, even_numbers: 2 }

  validates :street_id, :numbers_constraint, presence: true
  validates :numbers_range,
            format: { with: GaldakaoZone::RANGE_REGEXP },
            if: ->(z) { z.numbers_range.present? }
  validate :unique_combination

  private

  def unique_combination
    return unless GaldakaoZone.exists?(
      street_id: street_id,
      organization: organization,
      numbers_constraint: numbers_constraint,
      numbers_range: numbers_range
    )
    errors.add(:name, :invalid)
  end
end
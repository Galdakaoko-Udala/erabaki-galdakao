# frozen_string_literal: true
class GaldakaoZoneStreet < ApplicationRecord
  RANGE_REGEXP = /(\A\d+(-(\d+)*)\z)|(\A[\d+(,\d)*]+\z)/.freeze

  belongs_to :zone, class_name: "GaldakaoZone"
  belongs_to :street, class_name: "GaldakaoStreet"

  enum numbers_constraint: { all_numbers: 0, odd_numbers: 1, even_numbers: 2 }

  validates :street, :numbers_constraint, presence: true
  validates :numbers_range,
            format: { with: GaldakaoZoneStreet::RANGE_REGEXP },
            if: ->(zs) { zs.numbers_range.present? }
end

# frozen_string_literal: true

class GaldakaoZoneStreet < ApplicationRecord
  RANGE_REGEXP = /\A\d+(-\d+)?(,\d+(-\d+)?)*\z/

  belongs_to :zone, class_name: "GaldakaoZone"
  belongs_to :street, class_name: "GaldakaoStreet"

  enum :numbers_constraint, {
    all_numbers: 0,
    odd_numbers: 1,
    even_numbers: 2,
    only_range: 3,
    except_range: 4
  }

  RANGE_REQUIRED = %w(only_range except_range).freeze

  validates :numbers_constraint, presence: true
  validates :numbers_range,
            presence: true,
            if: ->(zs) { zs.numbers_constraint.in?(RANGE_REQUIRED) }
  validates :numbers_range,
            format: { with: GaldakaoZoneStreet::RANGE_REGEXP },
            if: ->(zs) { zs.numbers_range.present? }
end

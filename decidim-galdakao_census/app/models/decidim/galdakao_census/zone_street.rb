# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    # A street included in a zone, optionally restricted to some of its portal numbers.
    class ZoneStreet < ApplicationRecord
      include Decidim::Traceable
      include Decidim::Loggable

      RANGE_REGEXP = /\A\d+(-\d+)?(,\d+(-\d+)?)*\z/
      RANGE_REQUIRED = %w(only_range except_range).freeze

      belongs_to :zone
      belongs_to :street

      enum :numbers_constraint, {
        all_numbers: 0,
        odd_numbers: 1,
        even_numbers: 2,
        only_range: 3,
        except_range: 4
      }

      validates :numbers_constraint, presence: true
      validates :numbers_range,
                presence: true,
                if: ->(zone_street) { zone_street.numbers_constraint.in?(RANGE_REQUIRED) }
      validates :numbers_range,
                format: { with: RANGE_REGEXP },
                if: ->(zone_street) { zone_street.numbers_range.present? }

      # Whether a portal number of this street belongs to the zone
      def allows_number?(number)
        return false unless passes_parity?(number)
        return true if numbers_range.blank?

        in_range = numbers_range_segments.any? { |segment| segment.cover?(number) }
        except_range? ? !in_range : in_range
      end

      private

      def passes_parity?(number)
        return number.even? if even_numbers?
        return number.odd? if odd_numbers?

        true
      end

      # "1-10,15" => [1..10, 15..15]
      def numbers_range_segments
        numbers_range.split(",").map do |segment|
          first, last = segment.split("-").map(&:to_i)
          first..(last || first)
        end
      end
    end
  end
end

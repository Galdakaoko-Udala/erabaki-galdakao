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
      validate :numbers_range_format, if: ->(zone_street) { zone_street.numbers_range.present? }

      # Well formed and with every segment in ascending order ("10-1" is rejected)
      def self.valid_numbers_range?(value)
        RANGE_REGEXP.match?(value) && parse_numbers_range(value).all? { |segment| segment.begin <= segment.end }
      end

      # "1-10,15" => [1..10, 15..15]
      def self.parse_numbers_range(value)
        value.split(",").map do |segment|
          first, last = segment.split("-").map(&:to_i)
          first..(last || first)
        end
      end

      # Whether a portal number of this street belongs to the zone
      def allows_number?(number)
        return false unless passes_parity?(number)
        return true if numbers_range.blank?

        in_range = self.class.parse_numbers_range(numbers_range).any? { |segment| segment.cover?(number) }
        except_range? ? !in_range : in_range
      end

      private

      def passes_parity?(number)
        return number.even? if even_numbers?
        return number.odd? if odd_numbers?

        true
      end

      def numbers_range_format
        errors.add(:numbers_range, :invalid) unless self.class.valid_numbers_range?(numbers_range)
      end
    end
  end
end

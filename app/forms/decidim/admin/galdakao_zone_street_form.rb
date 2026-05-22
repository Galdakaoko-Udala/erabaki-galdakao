# frozen_string_literal: true
module Decidim
  module Admin
    class GaldakaoZoneStreetForm < Form
      mimic :galdakao_zone_street

      attribute :street_id,          Integer
      attribute :numbers_constraint,  String, default: "all_numbers"
      attribute :numbers_range,       String

      validates :street_id, :numbers_constraint, presence: true
      validates :numbers_range,
                presence: true,
                if: ->(form) { form.numbers_constraint.in?(GaldakaoZoneStreet::RANGE_REQUIRED) }
      validates :numbers_range,
                format: { with: GaldakaoZoneStreet::RANGE_REGEXP },
                if: ->(form) { form.numbers_range.present? }

      def numbers_constraint_options
        {
          "Todos los números"        => "all_numbers",
          "Números pares"            => "even_numbers",
          "Números impares"          => "odd_numbers",
          "Solo estos portales"      => "only_range",
          "Todos menos estos portales" => "except_range"
        }
      end
    end
  end
end
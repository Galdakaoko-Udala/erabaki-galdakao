# frozen_string_literal: true
module Decidim
  module Admin
    class GaldakaoZoneStreetForm < Form
      mimic :galdakao_zone_street
      attribute :street_id,           Integer
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
        base = "decidim.admin.galdakao.zone_streets.form.numbers_constraint_options"
        {
          I18n.t("#{base}.all_numbers")   => "all_numbers",
          I18n.t("#{base}.even_numbers")  => "even_numbers",
          I18n.t("#{base}.odd_numbers")   => "odd_numbers",
          I18n.t("#{base}.only_range")    => "only_range",
          I18n.t("#{base}.except_range")  => "except_range"
        }
      end
    end
  end
end

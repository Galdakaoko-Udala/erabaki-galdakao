# frozen_string_literal: true
module Decidim
  module Admin
    class UpdateGaldakaoZoneStreet < Decidim::Command
      def initialize(form, zone_street)
        @form = form
        @zone_street = zone_street
      end

      def call
        return broadcast(:invalid) unless form.valid?

        begin
          update_zone_street!
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        broadcast(:ok, zone_street)
      end

      private

      attr_reader :form, :zone_street

      def update_zone_street!
        zone_street.update!(
          street_id:          form.street_id,
          numbers_constraint: form.numbers_constraint,
          numbers_range:      form.numbers_range
        )
      end
    end
  end
end

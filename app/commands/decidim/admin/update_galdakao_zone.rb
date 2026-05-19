# frozen_string_literal: true

module Decidim
  module Admin
    class UpdateGaldakaoZone < Decidim::Command
      def initialize(form)
        @form = form
      end

      def call
        return broadcast(:invalid) unless form.valid?

        begin
          update_zone!
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        broadcast(:ok, zone)
      end

      private

      attr_reader :form, :zone

      def update_zone!
        @zone = GaldakaoZone.find(form.id)
        @zone.street_id          = form.street_id
        @zone.numbers_constraint = form.numbers_constraint
        @zone.numbers_range      = form.numbers_range
        @zone.name               = form.name
        @zone.save!
      end
    end
  end
end
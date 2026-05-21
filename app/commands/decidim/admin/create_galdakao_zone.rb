# frozen_string_literal: true
module Decidim
  module Admin
    class CreateGaldakaoZone < Decidim::Command
      def initialize(form)
        @form = form
      end

      def call
        return broadcast(:invalid) unless form.valid?

        begin
          create_zone!
        rescue StandardError => e
          return broadcast(:invalid, e.message)
        end

        broadcast(:ok, zone)
      end

      private

      attr_reader :form, :zone

      def create_zone!
        @zone = GaldakaoZone.create!(
          organization: form.current_organization,
          name:         form.name
        )
      end
    end
  end
end

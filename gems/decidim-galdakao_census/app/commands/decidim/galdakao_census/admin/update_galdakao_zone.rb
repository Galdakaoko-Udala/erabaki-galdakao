# frozen_string_literal: true
module Decidim
  module GaldakaoCensus
    module Admin
      class UpdateGaldakaoZone < Decidim::Command
        def initialize(form, zone)
          @form = form
          @zone = zone
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
          zone.update!(name: form.name)
        end
      end
    end
  end
end

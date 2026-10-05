# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Adds a street to a zone, registering the action in the admin log.
      class CreateZoneStreet < Decidim::Commands::CreateResource
        fetch_form_attributes :zone, :street_id, :numbers_constraint, :numbers_range

        protected

        def resource_class = Decidim::GaldakaoCensus::ZoneStreet
      end
    end
  end
end

# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Creates a zone, registering the action in the admin log.
      class CreateZone < Decidim::Commands::CreateResource
        fetch_form_attributes :name, :organization

        protected

        def resource_class = Decidim::GaldakaoCensus::Zone
      end
    end
  end
end

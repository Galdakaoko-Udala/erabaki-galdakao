# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Removes a street from a zone, registering the action in the admin log.
      class DestroyZoneStreet < Decidim::Commands::DestroyResource
      end
    end
  end
end

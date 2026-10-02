# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Destroys a zone and its streets, registering the action in the admin log.
      class DestroyZone < Decidim::Commands::DestroyResource
      end
    end
  end
end

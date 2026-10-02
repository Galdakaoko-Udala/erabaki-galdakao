# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Updates a zone, registering the action in the admin log.
      class UpdateZone < Decidim::Commands::UpdateResource
        fetch_form_attributes :name
      end
    end
  end
end

# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Updates a street of a zone, registering the action in the admin log.
      class UpdateZoneStreet < Decidim::Commands::UpdateResource
        fetch_form_attributes :street_id, :numbers_constraint, :numbers_range
      end
    end
  end
end

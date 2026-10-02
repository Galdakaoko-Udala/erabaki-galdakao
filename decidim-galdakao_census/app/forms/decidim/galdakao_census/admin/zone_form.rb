# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # A form to create or update a zone.
      class ZoneForm < Decidim::Form
        mimic :zone

        attribute :name, String

        validates :name, presence: true

        alias organization current_organization
      end
    end
  end
end

# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    # A street of the municipal register, synced from the census webservice.
    class Street < ApplicationRecord
      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"

      has_many :zone_streets, dependent: :restrict_with_error

      # Path to each street in the ListadoCalles operation response:
      #   <calles><Calle>Street name</Calle>...</calles>
      STREETS_XPATH = "//calles/Calle"

      # Syncs the streets from the municipal register SOAP API into Decidim's database.
      # Streets that no longer come from the register are kept, as they may be used in zones;
      # their updated_at shows the last sync in which they were present.
      # Returns false, without touching the database, when the service is unavailable.
      def self.import_streets!(organization)
        street_names = import_streets
        return false if street_names.nil?

        street_names.each do |street_name|
          street = find_or_initialize_by(name: street_name, organization: organization)
          # rubocop:disable Rails/SkipsModelValidations
          street.touch if street.persisted?
          # rubocop:enable Rails/SkipsModelValidations
          street.save!
        end
        true
      end

      # Returns nil when the service is unavailable, so it can be told apart from an empty list
      def self.import_streets
        response = Webservice.new(Webservice::LIST_STREETS).response
        return if response.nil?

        response.xpath(STREETS_XPATH).map { |node| node.text.strip }.compact_blank
      end
    end
  end
end

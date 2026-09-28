# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    class GaldakaoStreet < ApplicationRecord
      belongs_to :organization,
                 foreign_key: "decidim_organization_id",
                 class_name: "Decidim::Organization"

      # Path to each street in the ListadoCalles operation response:
      #   <calles><calle>Street name</calle>...</calles>
      STREETS_XPATH = "//calles/calle"

      # Syncs the streets from the municipal register SOAP API into Decidim's database.
      def self.import_streets!(organization)
        import_streets.each do |street_name|
          s = GaldakaoStreet.find_or_initialize_by(name: street_name, organization: organization)
          # rubocop:disable Rails/SkipsModelValidations
          s.touch if s.persisted?
          # rubocop:enable Rails/SkipsModelValidations
          s.save!
        end
      end

      def self.import_streets
        service = GaldakaoWebservice.new(GaldakaoWebservice::LIST_STREETS)
        service.response.xpath(STREETS_XPATH).map { |node| node.text.strip }.compact_blank
      end
    end
  end
end

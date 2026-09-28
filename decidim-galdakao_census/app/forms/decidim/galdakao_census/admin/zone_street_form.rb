# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # A form to add a street to a zone or to update it. The zone comes from the context.
      class ZoneStreetForm < Decidim::Form
        mimic :zone_street

        attribute :street_id, Integer
        attribute :numbers_constraint, String, default: "all_numbers"
        attribute :numbers_range, String

        validates :street_id, :numbers_constraint, presence: true
        validates :numbers_constraint, inclusion: { in: ZoneStreet.numbers_constraints.keys }
        validates :numbers_range, presence: true, if: :numbers_range_required?
        validates :numbers_range, format: { with: ZoneStreet::RANGE_REGEXP }, allow_blank: true
        validate :street_belongs_to_organization

        def zone
          context[:zone]
        end

        # Only kept for the constraints that use it
        def numbers_range
          super if numbers_range_required?
        end

        def numbers_constraint_options
          ZoneStreet.numbers_constraints.keys.map do |constraint|
            [I18n.t(constraint, scope: "decidim.galdakao_census.numbers_constraints"), constraint]
          end
        end

        def street_options
          Street.where(organization: current_organization).order(:name).pluck(:name, :id)
        end

        private

        def numbers_range_required?
          numbers_constraint.in?(ZoneStreet::RANGE_REQUIRED)
        end

        def street_belongs_to_organization
          return if street_id.blank?
          return if Street.exists?(id: street_id, organization: current_organization)

          errors.add(:street_id, :invalid)
        end
      end
    end
  end
end

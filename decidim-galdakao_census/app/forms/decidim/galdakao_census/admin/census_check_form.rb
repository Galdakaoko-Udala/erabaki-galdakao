# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # A form to validate a citizen against the register from the admin, to diagnose verification problems.
      # Unlike the authorization handler, it neither locks the admin out nor creates an authorization.
      class CensusCheckForm < Decidim::Form
        mimic :census_check

        attribute :document_number, String
        attribute :date_of_birth, Date

        validates :date_of_birth, presence: true
        validates :document_number, presence: true, format: { with: CensusAuthorizationHandler::DOCUMENT_FORMAT }

        def document_number
          super.to_s.strip.upcase.presence
        end

        def response
          return @response if defined?(@response)

          @response = Webservice.authenticate(document_number, date_of_birth)
        end
      end
    end
  end
end

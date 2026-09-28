# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    class CensusActionAuthorizer < Decidim::Verifications::DefaultActionAuthorizer
      I18N_SCOPE = "decidim.galdakao_census.action_authorizer"

      # The "zones" option is handled here instead of in the base class, where it would be
      # treated as a metadata field that the authorization is missing. It is removed from
      # a copy of the options: the original hash belongs to the component permissions and
      # is reused for every action checked in the same request.
      def initialize(authorization, options, component, resource)
        options = (options || {}).to_h
        @zone_ids = options["zones"].to_s.split(",").map(&:strip).compact_blank

        super(authorization, options.except("zones"), component, resource)
      end

      def authorize
        status_code, data = *super
        return [status_code, data] unless status_code == :ok
        return [status_code, data] if zone_ids.empty?
        return unauthorized("address_not_found") unless address?
        return [status_code, data] if belongs_to_zone?

        unauthorized("not_in_zone")
      end

      private

      attr_reader :zone_ids

      def unauthorized(reason)
        [:unauthorized, { extra_explanation: { key: reason, params: { scope: I18N_SCOPE } } }]
      end

      def authorization_street
        authorization.metadata["street"]
      end

      def authorization_number
        authorization.metadata["street_number"].to_i
      end

      # Authorizations created before portals were stored as nil may contain 0
      def address?
        authorization_street.present? && authorization_number.positive?
      end

      def belongs_to_zone?
        zones = Zone.where(organization: authorization.user.organization, id: zone_ids)

        ZoneStreet
          .where(zone: zones)
          .joins(:street)
          .where(Street.table_name => { name: authorization_street })
          .any? { |zone_street| zone_street.allows_number?(authorization_number) }
      end
    end
  end
end

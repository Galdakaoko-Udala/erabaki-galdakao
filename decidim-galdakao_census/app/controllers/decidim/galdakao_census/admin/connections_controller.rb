# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Checks the connection with the municipal register and validates a citizen against it.
      class ConnectionsController < Admin::ApplicationController
        # The register may not implement TestDBconnection, so the street list is requested as a fallback
        CONNECTION_ACTIONS = [Webservice::TEST_CONNECTION, Webservice::LIST_STREETS].freeze

        helper_method :connection_action, :connection_response, :soap_body

        def show
          enforce_permission_to :read, :census_connection

          @form = form(CensusCheckForm).instance
        end

        def check
          enforce_permission_to :check, :census_connection

          @form = form(CensusCheckForm).from_params(params)
          @checked = @form.valid?

          Rails.logger.info "#{Webservice::LOG_PREFIX} Census check requested by admin user ##{current_user.id}" if @checked
          render :show
        end

        private

        def connection_action
          connection_check.first
        end

        def connection_response
          connection_check.last
        end

        def connection_check
          return @connection_check if @connection_check

          CONNECTION_ACTIONS.each do |action|
            response = Webservice.new(action).response
            return @connection_check = [action, response] if response
          end

          @connection_check = [CONNECTION_ACTIONS.first, nil]
        end

        # Serialized as UTF-8 so that accented characters are not shown as XML entities
        def soap_body(response)
          return if response.nil?

          response.search("Body").children.to_xml(encoding: "UTF-8")
        end
      end
    end
  end
end

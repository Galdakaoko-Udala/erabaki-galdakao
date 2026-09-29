# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    module Admin
      # Checks the connection with the municipal register and validates a citizen against it.
      class ConnectionsController < Admin::ApplicationController
        helper_method :connection_response, :soap_body

        def show
          enforce_permission_to :read, :census_connection

          @form = form(CensusCheckForm).instance
        end

        def check
          enforce_permission_to :check, :census_connection

          @form = form(CensusCheckForm).from_params(params)
          @checked = @form.valid?
          # Do not log the document number: it is personal data
          Rails.logger.info "#{Webservice::LOG_PREFIX} Census check requested by admin user ##{current_user.id}" if @checked
          render :show
        end

        private

        def connection_response
          @connection_response ||= Webservice.new(Webservice::TEST_CONNECTION).response
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

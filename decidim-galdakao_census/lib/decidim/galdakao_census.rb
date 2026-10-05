# frozen_string_literal: true

require "decidim/galdakao_census/admin"
require "decidim/galdakao_census/engine"
require "decidim/galdakao_census/admin_engine"

module Decidim
  # Verification against the Galdakao municipal register and permissions by zone.
  module GaldakaoCensus
    include ActiveSupport::Configurable

    # URL of the municipal register SOAP service
    config_accessor :census_url do
      Decidim::Env.new("CENSUS_URL").value
    end

    # Mutual TLS with the census service. The certificate settings are file paths.
    config_accessor :tls_enabled do
      Decidim::Env.new("GALDAKAO_CENSUS_TLS").present?
    end

    config_accessor :tls_ca_cert do
      Decidim::Env.new("GALDAKAO_CENSUS_TLS_CERT").value
    end

    config_accessor :tls_client_cert do
      Decidim::Env.new("GALDAKAO_CENSUS_TLS_CLIENT_CERT").value
    end

    config_accessor :tls_client_key do
      Decidim::Env.new("GALDAKAO_CENSUS_TLS_CLIENT_KEY").value
    end

    # Seconds. Without them, a hung service would block the request thread for minutes.
    config_accessor :open_timeout do
      Decidim::Env.new("GALDAKAO_CENSUS_OPEN_TIMEOUT", 5).to_i
    end

    config_accessor :timeout do
      Decidim::Env.new("GALDAKAO_CENSUS_TIMEOUT", 15).to_i
    end
  end
end

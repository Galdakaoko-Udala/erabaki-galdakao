# frozen_string_literal: true

module Decidim
  module GaldakaoCensus
    # SOAP client for the Galdakao municipal register.
    class Webservice
      # SOAP operations exposed by the municipal register service
      AUTHENTICATE = "autenticar"
      LIST_STREETS = "ListadoCalles"

      LOG_PREFIX = "[Galdakao-Census]"

      def initialize(action)
        @action = action
        @body = ""
      end

      attr_accessor :action, :body

      def response
        return @response if defined?(@response)

        if census_url.blank?
          Rails.logger.error "#{LOG_PREFIX} CENSUS_URL is not configured"
          return @response = nil
        end

        begin
          raw_response = faraday_client.post(census_url) do |request|
            request.headers["Content-Type"] = "text/xml; charset=UTF-8"
            request.body = request_body
          end

          # Do not log the response body: it contains personal data (e.g. the citizen's address)
          Rails.logger.info "#{LOG_PREFIX} [#{action}] SOAP status: #{raw_response.status}"

          unless raw_response.status.to_i == 200
            Rails.logger.error "#{LOG_PREFIX} [#{action}] SOAP error HTTP #{raw_response.status}"
            return @response = nil
          end

          xml = Nokogiri::XML(raw_response.body)
          xml.remove_namespaces!
          @response = xml
        rescue Faraday::Error, SystemCallError, OpenSSL::OpenSSLError => e
          # SystemCallError and OpenSSLError come from missing or invalid TLS certificate files
          Rails.logger.error "#{LOG_PREFIX} [#{action}] SOAP connection error: #{e.class}: #{e.message}"
          @response = nil
        end
      end

      private

      delegate :census_url, :tls_enabled, :tls_ca_cert, :tls_client_cert, :tls_client_key,
               :open_timeout, :timeout, to: "Decidim::GaldakaoCensus", private: true

      def faraday_client
        Rails.logger.info "#{LOG_PREFIX} TLS: #{tls_enabled ? "enabled" : "disabled"}"

        return Faraday.new(request: timeouts) unless tls_enabled

        log_missing_tls_setting(:tls_ca_cert, "GALDAKAO_CENSUS_TLS_CERT")
        log_missing_tls_setting(:tls_client_cert, "GALDAKAO_CENSUS_TLS_CLIENT_CERT")
        log_missing_tls_setting(:tls_client_key, "GALDAKAO_CENSUS_TLS_CLIENT_KEY")

        Faraday.new(request: timeouts) do |f|
          f.ssl[:verify] = true
          f.ssl[:ca_file] = tls_ca_cert if tls_ca_cert.present?
          f.ssl[:client_cert] = OpenSSL::X509::Certificate.new(File.read(tls_client_cert)) if tls_client_cert.present?
          f.ssl[:client_key] = OpenSSL::PKey.read(File.read(tls_client_key)) if tls_client_key.present?
        end
      end

      def log_missing_tls_setting(setting, env_name)
        return if send(setting).present?

        Rails.logger.error "#{LOG_PREFIX} TLS is enabled but #{env_name} is not configured"
      end

      def timeouts
        { open_timeout:, timeout: }
      end

      def request_body
        element = body.strip.empty? ? "<tns:#{action}/>" : "<tns:#{action}>#{body.strip}</tns:#{action}>"
        @request_body ||= <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
                         xmlns:tns="http://example.com/soap">
            <soap:Body>
              #{element}
            </soap:Body>
          </soap:Envelope>
        XML
      end
    end
  end
end

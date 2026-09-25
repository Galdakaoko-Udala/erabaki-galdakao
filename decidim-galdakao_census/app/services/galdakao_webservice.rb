# frozen_string_literal: true

class GaldakaoWebservice
  def initialize(action)
    @action = action
    @body = ""
  end

  attr_accessor :action, :body

  def response
    return @response if defined?(@response)

    census_url = ENV.fetch("CENSUS_URL", nil)

    if census_url.blank?
      Rails.logger.error "[Galdakao-Census] CENSUS_URL no configurado"
      return @response = nil
    end

    begin
      raw_response = faraday_client.post(census_url) do |request|
        request.headers["Content-Type"] = "text/xml; charset=UTF-8"
        request.body = request_body
      end

      Rails.logger.info "[Galdakao-Census] [#{action}] SOAP status: #{raw_response.status}"
      Rails.logger.info "[Galdakao-Census] [#{action}] SOAP body: #{raw_response.body}"

      unless raw_response.status.to_i == 200
        Rails.logger.error "[Galdakao-Census] [#{action}] SOAP error HTTP #{raw_response.status}"
        return @response = nil
      end

      xml = Nokogiri::XML(raw_response.body)
      xml.remove_namespaces!
      @response = xml
    rescue Faraday::Error => e
      Rails.logger.error "[Galdakao-Census] [#{action}] SOAP connection error: #{e.message}"
      @response = nil
    end
  end

  def slim_response
    response&.search("Body")&.children
  end

  private

  def faraday_client
    tls_enabled = ENV["GALDAKAO_CENSUS_TLS"].to_s.downcase == "true"
    ca_cert = ENV["GALDAKAO_CENSUS_TLS_CERT"].to_s.strip
    client_cert = ENV["GALDAKAO_CENSUS_TLS_CLIENT_CERT"].to_s.strip
    client_key = ENV["GALDAKAO_CENSUS_TLS_CLIENT_KEY"].to_s.strip

    Rails.logger.info "[Galdakao-Census] TLS: #{tls_enabled ? "activo" : "desactivado"}"

    return Faraday.new unless tls_enabled

    Rails.logger.error "[Galdakao-Census] TLS activo pero GALDAKAO_CENSUS_TLS_CERT no definido" if ca_cert.blank?
    Rails.logger.error "[Galdakao-Census] TLS activo pero GALDAKAO_CENSUS_TLS_CLIENT_CERT no definido" if client_cert.blank?
    Rails.logger.error "[Galdakao-Census] TLS activo pero GALDAKAO_CENSUS_TLS_CLIENT_KEY no definido" if client_key.blank?

    Faraday.new do |f|
      f.ssl[:verify] = true
      f.ssl[:ca_file] = ca_cert if ca_cert.present?
      f.ssl[:client_cert] = OpenSSL::X509::Certificate.new(File.read(client_cert)) if client_cert.present?
      f.ssl[:client_key] = OpenSSL::PKey::RSA.new(File.read(client_key)) if client_key.present?
    end
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

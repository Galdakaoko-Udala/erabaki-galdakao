# frozen_string_literal: true

require "digest/md5"
require "faraday"
require "nokogiri"

class CensusAuthorizationHandler < Decidim::AuthorizationHandler
  attribute :document_number, String
  attribute :date_of_birth, Date

  validates :date_of_birth, presence: true
  validates :document_number,
            presence: true,
            format: { with: /\A[a-zA-Z]?\d{7,8}[a-zA-Z]\z/ }

  validate :document_number_valid

  # Se guarda en decidim_authorizations.metadata (JSON)
  # RGPD: contiene fecha de nacimiento y calle de empadronamiento (dato personal)
  def metadata
    super.merge(
      date_of_birth: date_of_birth&.strftime("%Y-%m-%d"),
      streets: [response&.xpath("//autenticarResult/calle")&.text&.strip].compact.reject(&:empty?)
    )
  end

  def unique_id
    Digest::MD5.hexdigest("#{document_number&.upcase}-#{Rails.application.secrets.secret_key_base}")
  end

  def slim_response
    response&.search("Body")&.children
  end

  private

  def sanitized_date_of_birth
    date_of_birth&.strftime("%Y-%m-%d")
  end

  def sanitized_document_number
    document_number.to_s[/\d+/]
  end

  def sanitized_document_letter
    document_number.to_s[/[a-zA-Z]\z/]&.upcase
  end

  # VALIDACIÓN PRINCIPAL
  def document_number_valid
    return if errors.any? # si ya falló el formato, no llamamos a la API

    soap_response = response

    if soap_response.nil?
      errors.add(:base, I18n.t("census_authorization_handler.service_unavailable"))
      return
    end

    result = soap_response.at_xpath("//autenticarResult/autenticarResult")&.text

    unless result == "true"
      errors.add(:document_number, I18n.t("census_authorization_handler.no_record"))
    end
  end

  # LLAMADA SOAP SEGURA
  # NOTA: cuando tu API devuelva la calle del ciudadano en la respuesta de
  # autenticación, debe ir dentro de un nodo <calle>. Si el nodo se llama
  # diferente (p.ej. <nombreCalle>), actualiza el xpath en metadata arriba.
  def response
    return @response if defined?(@response)

    Rails.logger.info ">> DEV aLabs >> ENV CENSUS_URL directo: #{ENV['CENSUS_URL'].inspect}"
    census_url = ENV["CENSUS_URL"] || Rails.application.secrets.census_url
    Rails.logger.info ">> DEV aLabs >> Census URL: #{census_url.inspect}"

    if census_url.blank?
      Rails.logger.error ">> DEV aLabs >> CENSUS_URL no configurado"
      return @response = nil
    end

    begin
      faraday_response = Faraday.post(census_url) do |request|
        request.headers["Content-Type"] = "text/xml; charset=UTF-8"
        request.body = request_body
      end

      Rails.logger.info ">> DEV aLabs >> SOAP status: #{faraday_response.status}"
      Rails.logger.info ">> DEV aLabs >> SOAP body: #{faraday_response.body}"

      if faraday_response.status.to_i != 200
        Rails.logger.error ">> DEV aLabs >> SOAP error HTTP #{faraday_response.status}"
        return @response = nil
      end

      xml = Nokogiri::XML(faraday_response.body)
      xml.remove_namespaces!

      @response = xml
    rescue Faraday::Error => e
      Rails.logger.error ">> DEV aLabs >> SOAP connection error: #{e.message}"
      @response = nil
    end
  end

  def request_body
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                    xmlns:tns="http://example.com/soap">
        <soap:Body>
          <tns:autenticar>
            <tns:dni>#{document_number&.upcase}</tns:dni>
            <tns:fecha_nacimiento>#{sanitized_date_of_birth}</tns:fecha_nacimiento>
          </tns:autenticar>
        </soap:Body>
      </soap:Envelope>
    XML
  end
end

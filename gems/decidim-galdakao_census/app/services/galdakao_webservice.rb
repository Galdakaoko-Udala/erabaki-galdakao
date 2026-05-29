# frozen_string_literal: true

class GaldakaoWebservice
  def initialize(action)
    @action = action
    @body = ""
  end

  attr_accessor :action, :body

  def response
    return @response if defined?(@response)

    census_url = ENV["CENSUS_URL"]

    if census_url.blank?
      Rails.logger.error ">> DEV aLabs >> CENSUS_URL no configurado"
      return @response = nil
    end

    begin
      raw_response = Faraday.post(census_url) do |request|
        request.headers["Content-Type"] = "text/xml; charset=UTF-8"
        request.body = request_body
      end

      Rails.logger.info ">> DEV aLabs >> [#{action}] SOAP status: #{raw_response.status}"
      Rails.logger.info ">> DEV aLabs >> [#{action}] SOAP body: #{raw_response.body}"

      unless raw_response.status.to_i == 200
        Rails.logger.error ">> DEV aLabs >> [#{action}] SOAP error HTTP #{raw_response.status}"
        return @response = nil
      end

      xml = Nokogiri::XML(raw_response.body)
      xml.remove_namespaces!
      @response = xml
    rescue Faraday::Error => e
      Rails.logger.error ">> DEV aLabs >> [#{action}] SOAP connection error: #{e.message}"
      @response = nil
    end
  end

  def slim_response
    response&.search("Body")&.children
  end

  private

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

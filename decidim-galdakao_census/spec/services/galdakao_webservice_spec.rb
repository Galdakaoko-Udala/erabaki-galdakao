# frozen_string_literal: true

require "rails_helper"

RSpec.describe GaldakaoWebservice do
  subject(:webservice) { described_class.new(action) }

  let(:action) { "ConsultaDni" }
  let(:census_url) { "https://census.example.com/soap" }

  before do
    ENV["CENSUS_URL"] = census_url
    ENV["GALDAKAO_CENSUS_TLS"] = "false"
  end

  describe "#response" do
    context "when CENSUS_URL is not configured" do
      before { ENV["CENSUS_URL"] = "" }

      it "returns nil without performing any request" do
        expect(webservice.response).to be_nil
      end

      it "does not perform any HTTP call" do
        webservice.response
        expect(WebMock).not_to have_requested(:post, census_url)
      end
    end

    context "when the service responds successfully (200)" do
      let(:soap_response_body) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
            <soap:Body>
              <ConsultaDniResponse>
                <Resultado>OK</Resultado>
              </ConsultaDniResponse>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      before do
        stub_request(:post, census_url)
          .to_return(status: 200, body: soap_response_body, headers: { "Content-Type" => "text/xml" })
      end

      it "returns a Nokogiri::XML document" do
        expect(webservice.response).to be_a(Nokogiri::XML::Document)
      end

      it "strips namespaces from the XML" do
        expect(webservice.response.at_xpath("//Resultado").text).to eq("OK")
      end

      it "sends the correct Content-Type header" do
        webservice.response
        expect(WebMock).to have_requested(:post, census_url)
          .with(headers: { "Content-Type" => "text/xml; charset=UTF-8" })
      end

      it "memoizes the response and does not repeat the HTTP request" do
        webservice.response
        webservice.response
        expect(WebMock).to have_requested(:post, census_url).once
      end
    end

    context "when the service responds with an HTTP error (≠200)" do
      before do
        stub_request(:post, census_url).to_return(status: 500, body: "Internal Server Error")
      end

      it "returns nil" do
        expect(webservice.response).to be_nil
      end
    end

    context "when there is a connection error" do
      before do
        stub_request(:post, census_url).to_raise(Faraday::ConnectionFailed.new("connection refused"))
      end

      it "returns nil without raising the exception" do
        expect { webservice.response }.not_to raise_error
        expect(webservice.response).to be_nil
      end
    end
  end

  describe "#slim_response" do
    context "when there is a valid response" do
      let(:soap_response_body) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
            <soap:Body>
              <ConsultaDniResponse>
                <Resultado>OK</Resultado>
              </ConsultaDniResponse>
            </soap:Body>
          </soap:Envelope>
        XML
      end

      before do
        stub_request(:post, census_url)
          .to_return(status: 200, body: soap_response_body, headers: { "Content-Type" => "text/xml" })
      end

      it "returns the content inside Body" do
        expect(webservice.slim_response.to_s).to include("ConsultaDniResponse")
      end
    end

    context "when there is no response (response is nil)" do
      before { ENV["CENSUS_URL"] = "" }

      it "returns nil" do
        expect(webservice.slim_response).to be_nil
      end
    end
  end
end

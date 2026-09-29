# frozen_string_literal: true

require "rails_helper"

RSpec.describe Decidim::GaldakaoCensus::Webservice do
  subject(:webservice) { described_class.new(action) }

  let(:action) { "ConsultaDni" }
  let(:census_url) { "https://census.example.com/soap" }

  let(:config) { { census_url:, tls_enabled: false } }

  before do
    config.each { |name, value| allow(Decidim::GaldakaoCensus).to receive(name).and_return(value) }
  end

  describe "#response" do
    context "when CENSUS_URL is not configured" do
      let(:census_url) { nil }

      it "returns nil without performing any request" do
        expect(webservice.response).to be_nil
      end

      it "does not perform any HTTP call" do
        webservice.response
        expect(a_request(:any, /.*/)).not_to have_been_made
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

      it "does not log the response body, which may contain personal data" do
        logged = []
        [:debug, :info, :warn, :error].each do |level|
          allow(Rails.logger).to receive(level) { |message = nil, &block| logged << (message || block&.call).to_s }
        end

        webservice.response

        expect(logged.join("\n")).not_to include("Resultado")
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

    context "when the service does not answer in time" do
      before { stub_request(:post, census_url).to_timeout }

      it "returns nil without raising the exception" do
        expect { webservice.response }.not_to raise_error
        expect(webservice.response).to be_nil
      end
    end

    context "when TLS is enabled but the certificate files do not exist" do
      let(:config) do
        {
          census_url:,
          tls_enabled: true,
          tls_ca_cert: "/nonexistent/ca.crt",
          tls_client_cert: "/nonexistent/client.crt",
          tls_client_key: "/nonexistent/client.key"
        }
      end

      it "returns nil without raising the exception" do
        expect { webservice.response }.not_to raise_error
        expect(webservice.response).to be_nil
      end
    end
  end

  describe ".authenticate" do
    before { stub_request(:post, census_url).to_return(status: 200, body: "<autenticarResult/>") }

    it "sends the escaped document number and the date of birth to the autenticar operation" do
      described_class.authenticate("<X>", Date.new(1980, 1, 31))

      expect(
        a_request(:post, census_url).with do |request|
          request.body.include?("<tns:autenticar>") &&
            request.body.include?("<tns:dni>&lt;X&gt;</tns:dni>") &&
            request.body.include?("<tns:fecha_nacimiento>1980-01-31</tns:fecha_nacimiento>")
        end
      ).to have_been_made
    end

    it "returns the response document" do
      expect(described_class.authenticate("12345678Z", Date.new(1980, 1, 31))).to be_a(Nokogiri::XML::Document)
    end
  end

  describe "connection timeouts" do
    let(:config) { { census_url:, tls_enabled: false, open_timeout: 3, timeout: 7 } }

    it "uses the configured open and read timeouts" do
      options = webservice.send(:faraday_client).options

      expect(options.open_timeout).to eq(3)
      expect(options.timeout).to eq(7)
    end

    it "has explicit defaults" do
      expect(Decidim::GaldakaoCensus.config.open_timeout).to eq(5)
      expect(Decidim::GaldakaoCensus.config.timeout).to eq(15)
    end
  end
end

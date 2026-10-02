# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Admin::CensusCheckForm do
  subject(:form) { described_class.from_params(params) }

  let(:params) { { document_number: " 12345678z ", date_of_birth: Date.new(1980, 1, 1) } }
  let(:response) { Nokogiri::XML("<autenticarResult><autenticarResult>true</autenticarResult></autenticarResult>") }

  before do
    allow(Decidim::GaldakaoCensus::Webservice).to receive(:authenticate).and_return(response)
  end

  it { is_expected.to be_valid }

  it "normalizes the document number" do
    expect(form.document_number).to eq("12345678Z")
  end

  it "asks the register with the normalized data" do
    expect(form.response).to eq(response)
    expect(Decidim::GaldakaoCensus::Webservice).to have_received(:authenticate).with("12345678Z", Date.new(1980, 1, 1))
  end

  context "when the document number has an invalid format" do
    let(:params) { { document_number: "1234", date_of_birth: Date.new(1980, 1, 1) } }

    it { is_expected.not_to be_valid }
  end

  context "when the date of birth is missing" do
    let(:params) { { document_number: "12345678Z" } }

    it { is_expected.not_to be_valid }
  end
end

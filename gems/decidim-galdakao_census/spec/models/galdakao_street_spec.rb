# frozen_string_literal: true

require "rails_helper"

RSpec.describe GaldakaoStreet, type: :model do
  subject(:street) { build(:galdakao_street) }

  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to belong_to(:organization).class_name("Decidim::Organization") }
  end

  describe ".import_streets" do
    let(:organization) { create(:organization) }
    let(:webservice) { instance_double(GaldakaoWebservice) }
    let(:xml_response) { Nokogiri::XML("<calles><calle>Mayor</calle><calle>Iturribide</calle></calles>") }

    before do
      allow(GaldakaoWebservice).to receive(:new).with("ListadoCalles").and_return(webservice)
      allow(webservice).to receive(:response).and_return(xml_response)
    end

    it "returns the list of street names from the SOAP response" do
      expect(described_class.import_streets).to eq(%w(Mayor Iturribide))
    end
  end

  describe ".import_streets!" do
    let(:organization) { create(:organization) }

    before do
      allow(described_class).to receive(:import_streets).and_return(["Mayor", "Iturribide"])
    end

    it "creates a GaldakaoStreet for each imported name" do
      expect { described_class.import_streets!(organization) }
        .to change(described_class, :count).by(2)
    end

    it "does not duplicate streets that already exist" do
      create(:galdakao_street, name: "Mayor", organization:)

      expect { described_class.import_streets!(organization) }
        .to change(described_class, :count).by(1)
    end
  end
end
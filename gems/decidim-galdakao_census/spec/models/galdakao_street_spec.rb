# frozen_string_literal: true

require "rails_helper"

describe GaldakaoStreet do
  describe "associations" do
    it "belongs to an organization" do
      street = create(:galdakao_street)

      expect(street.organization).to be_a(Decidim::Organization)
    end
  end

  describe ".import_streets" do
    let(:webservice) { instance_double(GaldakaoWebservice, response: response) }
    let(:response) do
      Nokogiri::XML(<<~XML)
        <calles>
          <calle>Calle DePrueba</calle>
          <calle>Calle DeEjemplo</calle>
        </calles>
      XML
    end

    before do
      allow(GaldakaoWebservice).to receive(:new).with("ListadoCalles").and_return(webservice)
    end

    it "returns the street names parsed from the webservice response" do
      expect(described_class.import_streets).to eq(["Calle DePrueba", "Calle DeEjemplo"])
    end

    context "when the response includes a blank street name" do
      let(:response) do
        Nokogiri::XML(<<~XML)
          <calles>
            <calle>Calle DePrueba</calle>
            <calle>   </calle>
          </calles>
        XML
      end

      it "discards it" do
        expect(described_class.import_streets).to eq(["Calle DePrueba"])
      end
    end
  end

  describe ".import_streets!" do
    let(:organization) { create(:organization) }

    context "when the street does not exist yet" do
      before do
        allow(described_class).to receive(:import_streets).and_return(["Calle DePrueba", "Calle DeEjemplo"])
      end

      it "creates a street for each name returned by the webservice" do
        expect { described_class.import_streets!(organization) }
          .to change(described_class, :count).by(2)

        expect(described_class.pluck(:name)).to contain_exactly("Calle DePrueba", "Calle DeEjemplo")
      end

      it "associates the new street with the given organization" do
        described_class.import_streets!(organization)

        expect(described_class.find_by(name: "Calle DePrueba").organization).to eq(organization)
      end
    end

    context "when the street already exists for the organization" do
      before do
        allow(described_class).to receive(:import_streets).and_return(["Calle DePrueba"])
      end

      it "does not create a duplicate" do
        create(:galdakao_street, name: "Calle DePrueba", organization:)

        expect { described_class.import_streets!(organization) }
          .not_to change(described_class, :count)
      end

      it "touches the existing record instead of creating a new one" do
        existing = create(:galdakao_street, name: "Calle DePrueba", organization:)
        allow(described_class).to receive(:find_or_initialize_by).and_return(existing)

        expect(existing).to receive(:touch)

        described_class.import_streets!(organization)
      end
    end
  end
end

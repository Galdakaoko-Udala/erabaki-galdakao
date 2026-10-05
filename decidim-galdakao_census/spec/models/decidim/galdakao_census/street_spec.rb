# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::Street do
  describe "associations" do
    it "belongs to an organization" do
      street = create(:census_street)

      expect(street.organization).to be_a(Decidim::Organization)
    end
  end

  describe ".import_streets" do
    let(:webservice) { instance_double(Decidim::GaldakaoCensus::Webservice, response:) }
    let(:response) do
      Nokogiri::XML(<<~XML)
        <calles>
          <Calle>Calle DePrueba</Calle>
          <Calle>Calle DeEjemplo</Calle>
        </calles>
      XML
    end

    before do
      allow(Decidim::GaldakaoCensus::Webservice).to receive(:new).with("ListadoCalles").and_return(webservice)
    end

    it "returns the street names parsed from the webservice response" do
      expect(described_class.import_streets).to eq(["Calle DePrueba", "Calle DeEjemplo"])
    end

    context "when the response includes a blank street name" do
      let(:response) do
        Nokogiri::XML(<<~XML)
          <calles>
            <Calle>Calle DePrueba</Calle>
            <Calle>   </Calle>
          </calles>
        XML
      end

      it "discards it" do
        expect(described_class.import_streets).to eq(["Calle DePrueba"])
      end
    end

    context "when the webservice is unavailable" do
      let(:response) { nil }

      it "returns nil instead of raising" do
        expect(described_class.import_streets).to be_nil
      end
    end
  end

  describe ".import_streets!" do
    let(:organization) { create(:organization) }

    context "when a street is no longer returned by the register" do
      before { allow(described_class).to receive(:import_streets).and_return(["Kale Berria"]) }

      it "keeps it, as it may be used in zones" do
        old_street = create(:census_street, organization:, name: "Kale Zaharra")
        create(:census_zone_street, street: old_street, organization:)

        described_class.import_streets!(organization)

        expect(described_class.where(organization:).pluck(:name)).to contain_exactly("Kale Zaharra", "Kale Berria")
      end
    end

    context "when the webservice is unavailable" do
      before { allow(described_class).to receive(:import_streets).and_return(nil) }

      it "returns false and does not change the streets" do
        existing = create(:census_street, organization:)

        expect(described_class.import_streets!(organization)).to be(false)
        expect(described_class.where(organization:)).to contain_exactly(existing)
      end
    end

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
        create(:census_street, name: "Calle DePrueba", organization:)

        expect { described_class.import_streets!(organization) }
          .not_to change(described_class, :count)
      end

      it "touches the existing record instead of creating a new one" do
        existing = create(:census_street, name: "Calle DePrueba", organization:)
        allow(described_class).to receive(:find_or_initialize_by).and_return(existing)

        expect(existing).to receive(:touch)

        described_class.import_streets!(organization)
      end
    end
  end
end

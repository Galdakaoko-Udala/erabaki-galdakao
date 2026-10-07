# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::CensusAuthorizationHandler do
  subject(:handler) do
    described_class.new(document_number:, date_of_birth:, user:)
  end

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization:) }
  let(:document_number) { "12345678Z" }
  let(:date_of_birth) { Date.new(1990, 5, 12) }

  let(:lockout_manager) do
    instance_double(Decidim::GaldakaoCensus::LockoutManager, check_lockout: nil)
  end

  before do
    allow(Decidim::GaldakaoCensus::LockoutManager).to receive(:new).and_return(lockout_manager)
  end

  describe "validations" do
    context "with valid attributes" do
      before do
        allow(lockout_manager).to receive(:register_success)
        stub_webservice(result: "true")
      end

      it "is valid" do
        expect(handler).to be_valid
      end
    end

    context "without a date_of_birth" do
      let(:date_of_birth) { nil }

      it "is not valid" do
        expect(handler).not_to be_valid
      end
    end

    context "without a document_number" do
      let(:document_number) { nil }

      it "is not valid" do
        expect(handler).not_to be_valid
      end
    end

    context "with a document_number format" do
      context "when it is a valid DNI (8 digits and a letter)" do
        let(:document_number) { "12345678Z" }

        before do
          allow(lockout_manager).to receive(:register_success)
          stub_webservice(result: "true")
        end

        it "passes the format validation" do
          handler.valid?

          expect(handler.errors[:document_number]).to be_empty
        end
      end

      context "when it is a valid NIE (leading letter, digits, trailing letter)" do
        let(:document_number) { "X1234567L" }

        before do
          allow(lockout_manager).to receive(:register_success)
          stub_webservice(result: "true")
        end

        it "passes the format validation" do
          handler.valid?

          expect(handler.errors[:document_number]).to be_empty
        end
      end

      %w(12345678Z 12345678z Y1234567X 1234567L).each do |valid_document|
        context "when it is #{valid_document}, with a correct control letter" do
          let(:document_number) { valid_document }

          before do
            allow(lockout_manager).to receive(:register_success)
            stub_webservice(result: "true")
          end

          it "passes the validation" do
            handler.valid?

            expect(handler.errors[:document_number]).to be_empty
          end
        end
      end

      context "when the control letter is wrong" do
        let(:document_number) { "12345678A" }

        it "fails without calling the register nor counting a failed attempt" do
          expect(Decidim::GaldakaoCensus::Webservice).not_to receive(:new)
          expect(lockout_manager).not_to receive(:register_failed_attempt)

          expect(handler).not_to be_valid
          expect(handler.errors[:document_number]).not_to be_empty
        end
      end

      context "when it has a prefix that is not a NIE or K/L/M document" do
        let(:document_number) { "A1234567L" }

        it "fails the format validation" do
          handler.valid?

          expect(handler.errors[:document_number]).not_to be_empty
        end
      end

      context "when it has no trailing letter" do
        let(:document_number) { "12345678" }

        it "fails the format validation" do
          handler.valid?

          expect(handler.errors[:document_number]).not_to be_empty
        end
      end

      context "when it has too many digits" do
        let(:document_number) { "1234567890Z" }

        it "fails the format validation" do
          handler.valid?

          expect(handler.errors[:document_number]).not_to be_empty
        end
      end
    end
  end

  describe "lockout integration" do
    context "when the user is locked" do
      let(:lockout_manager) do
        instance_double(Decidim::GaldakaoCensus::LockoutManager, check_lockout: "please wait")
      end

      it "is not valid" do
        expect(handler).not_to be_valid
      end

      it "adds the lockout message as a base error" do
        handler.valid?

        expect(handler.errors[:base]).to include("please wait")
      end

      it "does not call the webservice" do
        expect(Decidim::GaldakaoCensus::Webservice).not_to receive(:new)

        handler.valid?
      end
    end

    shared_examples "a handler without lockout" do
      context "when the webservice confirms the document" do
        before { stub_webservice(result: "true") }

        it "is valid without using the lockout manager" do
          expect(handler).to be_valid
          expect(Decidim::GaldakaoCensus::LockoutManager).not_to have_received(:new)
        end
      end

      context "when the webservice rejects the document" do
        before { stub_webservice(result: "false") }

        it "is not valid without using the lockout manager" do
          expect(handler).not_to be_valid
          expect(handler.errors[:base]).to include(I18n.t("decidim.authorization_handlers.census_authorization_handler.not_in_census"))
          expect(Decidim::GaldakaoCensus::LockoutManager).not_to have_received(:new)
        end
      end
    end

    context "when there is no user" do
      let(:user) { nil }

      it_behaves_like "a handler without lockout"
    end

    # An admin creating a new managed user validates the handler before the user is saved
    context "when the user is not persisted" do
      let(:user) { build(:user, :managed, organization:) }

      it_behaves_like "a handler without lockout"

      context "with a real lockout manager" do
        before do
          allow(Decidim::GaldakaoCensus::LockoutManager).to receive(:new).and_call_original
          stub_webservice(result: "false")
        end

        it "does not raise" do
          expect { handler.valid? }.not_to raise_error
        end
      end
    end
  end

  describe "webservice integration" do
    context "when the webservice confirms the document" do
      before do
        allow(lockout_manager).to receive(:register_success)
        stub_webservice(result: "true")
      end

      it "is valid" do
        expect(handler).to be_valid
      end

      it "registers a successful attempt" do
        handler.valid?

        expect(lockout_manager).to have_received(:register_success)
      end
    end

    context "when the webservice rejects the document" do
      before do
        allow(lockout_manager).to receive(:register_failed_attempt).and_return("wrong document")
        stub_webservice(result: "false")
      end

      it "is not valid" do
        expect(handler).not_to be_valid
      end

      it "adds the lockout manager's message as a base error" do
        handler.valid?

        expect(handler.errors[:base]).to include("wrong document")
      end
    end

    context "when the webservice is unavailable" do
      before do
        unavailable_double = instance_double(Decidim::GaldakaoCensus::Webservice, response: nil)
        allow(unavailable_double).to receive(:body=)
        allow(Decidim::GaldakaoCensus::Webservice).to receive(:new).and_return(unavailable_double)
      end

      it "is not valid" do
        expect(handler).not_to be_valid
      end

      it "adds a service unavailable base error" do
        handler.valid?

        expect(handler.errors[:base]).to include(I18n.t("decidim.authorization_handlers.census_authorization_handler.service_unavailable"))
      end
    end

    context "when a previous validation has already failed" do
      let(:date_of_birth) { nil }

      it "does not call the webservice" do
        expect(Decidim::GaldakaoCensus::Webservice).not_to receive(:new)

        handler.valid?
      end
    end

    context "when validity is checked more than once" do
      before do
        allow(lockout_manager).to receive(:register_success)
        stub_webservice(result: "true")
      end

      it "only calls the webservice once" do
        expect(Decidim::GaldakaoCensus::Webservice).to receive(:new).once.and_return(webservice_double)

        handler.valid?
        handler.metadata
      end
    end
  end

  describe "#metadata" do
    before do
      stub_webservice(result: "true", street: "Calle Mayor", portal: "14")
    end

    it "includes the formatted date of birth" do
      expect(handler.metadata[:date_of_birth]).to eq("1990-05-12")
    end

    it "includes the street from the webservice response" do
      expect(handler.metadata[:street]).to eq("Calle Mayor")
    end

    it "includes the street number as an integer" do
      expect(handler.metadata[:street_number]).to eq(14)
    end

    context "when the webservice returns no portal" do
      before { stub_webservice(result: "true", street: "Calle Mayor", portal: "") }

      it "stores a nil street number instead of 0" do
        expect(handler.metadata[:street_number]).to be_nil
      end
    end

    context "when the portal has no digits" do
      before { stub_webservice(result: "true", street: "Calle Mayor", portal: "s/n") }

      it "stores a nil street number" do
        expect(handler.metadata[:street_number]).to be_nil
      end
    end

    context "when the portal includes a letter" do
      before { stub_webservice(result: "true", street: "Calle Mayor", portal: "14B") }

      it "stores the numeric part" do
        expect(handler.metadata[:street_number]).to eq(14)
      end
    end

    context "when the webservice returns no street" do
      before { stub_webservice(result: "true", street: "", portal: "14") }

      it "stores a nil street" do
        expect(handler.metadata[:street]).to be_nil
      end
    end
  end

  describe "#unique_id" do
    it "is deterministic for the same document number" do
      handler_a = described_class.new(document_number: "12345678Z", date_of_birth:, user:)
      handler_b = described_class.new(document_number: "12345678Z", date_of_birth:, user:)

      expect(handler_a.unique_id).to eq(handler_b.unique_id)
    end

    it "is the same regardless of the document number's case" do
      lower = described_class.new(document_number: "12345678z", date_of_birth:, user:)
      upper = described_class.new(document_number: "12345678Z", date_of_birth:, user:)

      expect(lower.unique_id).to eq(upper.unique_id)
    end

    it "differs between different document numbers" do
      other = described_class.new(document_number: "87654321X", date_of_birth:, user:)

      expect(handler.unique_id).not_to eq(other.unique_id)
    end
  end

  def webservice_double(result: "true", street: "Calle Mayor", portal: "4")
    double = instance_double(
      Decidim::GaldakaoCensus::Webservice,
      response: Nokogiri::XML(<<~XML)
        <autenticarResult>
          <autenticarResult>#{result}</autenticarResult>
          <calle>#{street}</calle>
          <portal>#{portal}</portal>
        </autenticarResult>
      XML
    )
    allow(double).to receive(:body=)
    double
  end

  def stub_webservice(result: "true", street: "Calle Mayor", portal: "4")
    allow(Decidim::GaldakaoCensus::Webservice).to receive(:new).and_return(
      webservice_double(result:, street:, portal:)
    )
  end
end

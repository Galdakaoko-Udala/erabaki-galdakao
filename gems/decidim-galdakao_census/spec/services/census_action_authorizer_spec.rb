# frozen_string_literal: true

require "rails_helper"

describe CensusActionAuthorizer do
  subject(:authorizer) { described_class.new(authorization, options, nil, nil) }

  let(:organization) { create(:organization) }
  let(:zone) { create(:galdakao_zone, organization:) }
  let(:street) { create(:galdakao_street, organization:, name: "Calle Mayor") }
  let(:options) { { "zones" => zone.id.to_s } }

  let(:authorization) do
    create(:authorization, metadata: { "street" => authorization_street, "street_number" => authorization_number })
  end
  let(:authorization_street) { "Calle Mayor" }
  let(:authorization_number) { 4 }

  describe "#authorize" do
    context "when there is no authorization" do
      let(:authorization) { nil }

      it "returns missing" do
        expect(authorizer.authorize).to eq([:missing, { action: :authorize }])
      end
    end

    context "when no zones are configured" do
      let(:options) { { "zones" => "" } }

      it "returns ok" do
        expect(authorizer.authorize).to eq([:ok, {}])
      end
    end

    context "when zones are configured" do
      before { create(:galdakao_zone_street, zone:, street:, numbers_constraint: "all_numbers") }

      context "when the authorization has no street" do
        let(:authorization_street) { nil }

        it "returns unauthorized" do
          expect(authorizer.authorize).to eq([:unauthorized, {}])
        end
      end

      context "when the authorization has no street_number" do
        let(:authorization_number) { nil }

        it "returns unauthorized" do
          expect(authorizer.authorize).to eq([:unauthorized, {}])
        end
      end

      context "when the street does not belong to any configured zone" do
        let(:authorization_street) { "Calle Otra" }

        it "returns unauthorized" do
          expect(authorizer.authorize).to eq([:unauthorized, {}])
        end
      end

      context "when the street belongs to a configured zone" do
        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end

      context "when the matching street is in the second of several configured zones" do
        let(:other_zone) { create(:galdakao_zone, organization:) }
        let(:options) { { "zones" => "#{other_zone.id},#{zone.id}" } }

        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end
    end
  end

  describe "number constraints" do
    context "when the constraint is all_numbers" do
      before { create(:galdakao_zone_street, zone:, street:, numbers_constraint: "all_numbers") }

      context "with an odd number" do
        let(:authorization_number) { 7 }

        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end

      context "with an even number" do
        let(:authorization_number) { 8 }

        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end
    end

    context "when the constraint is even_numbers" do
      before { create(:galdakao_zone_street, zone:, street:, numbers_constraint: "even_numbers") }

      context "with an even number" do
        let(:authorization_number) { 4 }

        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end

      context "with an odd number" do
        let(:authorization_number) { 5 }

        it "returns unauthorized" do
          expect(authorizer.authorize).to eq([:unauthorized, {}])
        end
      end
    end

    context "when the constraint is odd_numbers" do
      before { create(:galdakao_zone_street, zone:, street:, numbers_constraint: "odd_numbers") }

      context "with an odd number" do
        let(:authorization_number) { 5 }

        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end

      context "with an even number" do
        let(:authorization_number) { 4 }

        it "returns unauthorized" do
          expect(authorizer.authorize).to eq([:unauthorized, {}])
        end
      end
    end

    context "when the constraint is only_range" do
      before do
        create(:galdakao_zone_street, zone:, street:, numbers_constraint: "only_range", numbers_range: "1-10")
      end

      context "with a number inside the range" do
        let(:authorization_number) { 5 }

        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end

      context "with a number outside the range" do
        let(:authorization_number) { 20 }

        it "returns unauthorized" do
          expect(authorizer.authorize).to eq([:unauthorized, {}])
        end
      end
    end

    context "when the constraint is except_range" do
      before do
        create(:galdakao_zone_street, zone:, street:, numbers_constraint: "except_range", numbers_range: "1-10")
      end

      context "with a number inside the excluded range" do
        let(:authorization_number) { 5 }

        it "returns unauthorized" do
          expect(authorizer.authorize).to eq([:unauthorized, {}])
        end
      end

      context "with a number outside the excluded range" do
        let(:authorization_number) { 20 }

        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end
    end

    context "when numbers_range combines individual numbers and ranges" do
      before do
        create(:galdakao_zone_street, zone:, street:, numbers_constraint: "only_range", numbers_range: "1-4,7,10-12")
      end

      context "with a number inside one of the individual values" do
        let(:authorization_number) { 7 }

        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end

      context "with a number inside one of the ranges" do
        let(:authorization_number) { 11 }

        it "returns ok" do
          expect(authorizer.authorize).to eq([:ok, {}])
        end
      end

      context "with a number in none of the values or ranges" do
        let(:authorization_number) { 8 }

        it "returns unauthorized" do
          expect(authorizer.authorize).to eq([:unauthorized, {}])
        end
      end
    end
  end
end

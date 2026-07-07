# frozen_string_literal: true

require "rails_helper"

describe Decidim::GaldakaoCensus::LockoutManager do
  subject(:manager) { described_class.new(user) }

  let(:organization) { create(:organization) }
  let(:user) { create(:user, organization:) }
  let(:handler_key) { described_class::HANDLER_KEY }

  describe "#check_lockout" do
    context "when the user has no previous lockout data" do
      it "returns nil" do
        expect(manager.check_lockout).to be_nil
      end
    end

    context "when the previous lock has already expired" do
      before do
        user.update(
          extended_data: { "authorizations" => { handler_key => { "locked_until" => 1.minute.ago.to_s } } }
        )
      end

      it "returns nil" do
        expect(manager.check_lockout).to be_nil
      end
    end

    context "when the user is locked indefinitely" do
      before do
        user.update(
          extended_data: { "authorizations" => { handler_key => { "locked_until" => "infinite" } } }
        )
      end

      it "returns the indefinite lockout message" do
        expect(manager.check_lockout).to eq(I18n.t("decidim.galdakao_census.lockout.blocked_indefinitely"))
      end
    end

    context "when the user is temporarily locked" do
      before do
        user.update(
          extended_data: { "authorizations" => { handler_key => { "locked_until" => 30.seconds.from_now.to_s } } }
        )
      end

      it "returns a wait message with the remaining time" do
        travel_to(30.seconds.from_now - 10.seconds) do
          result = manager.check_lockout

          expect(result).to eq(I18n.t("decidim.galdakao_census.lockout.wait", minutes: 0, seconds: 10))
        end
      end
    end
  end

  describe "#register_failed_attempt" do
    context "on the first failed attempt" do
      it "locks the user softly and reports the remaining attempts" do
        message = manager.register_failed_attempt

        expected_wait = "#{I18n.t("decidim.galdakao_census.lockout.wait", minutes: 0, seconds: 30)}\n"
        expected_remaining = I18n.t("decidim.galdakao_census.lockout.attempts_remaining", remaining: 5)
        expect(message).to eq("#{expected_wait}#{expected_remaining}")
      end

      it "stores a soft lock of 30 seconds" do
        travel_to(Time.current) do
          manager.register_failed_attempt

          data = user.reload.extended_data.dig("authorizations", handler_key)
          expect(data["failed_attempts"]).to eq(1)
          expect(Time.parse(data["locked_until"].to_s)).to be_within(1.second).of(30.seconds.from_now)
        end
      end
    end

    context "on the third failed attempt" do
      before do
        2.times { manager.register_failed_attempt }
      end

      it "locks the user for 5 minutes and reports the three-attempts message" do
        message = manager.register_failed_attempt

        expected_wait = "#{I18n.t("decidim.galdakao_census.lockout.wait", minutes: 5, seconds: 0)}\n"
        expected_notice = I18n.t("decidim.galdakao_census.lockout.three_attempts")
        expect(message).to eq("#{expected_wait}#{expected_notice}")
      end
    end

    context "on the sixth failed attempt" do
      before do
        5.times { manager.register_failed_attempt }
      end

      it "locks the user indefinitely" do
        manager.register_failed_attempt

        expect(manager).to be_locked_indefinitely
      end

      it "returns the indefinite lockout contact message" do
        message = manager.register_failed_attempt

        expect(message).to eq(I18n.t("decidim.galdakao_census.lockout.blocked_indefinitely_contact"))
      end

      it "notifies the organization admins" do
        expect(Decidim::EventsManager).to receive(:publish).with(
          hash_including(
            event: "decidim.events.galdakao_census.user_locked",
            event_class: Decidim::GaldakaoCensus::UserLockedEvent,
            resource: user
          )
        )

        manager.register_failed_attempt
      end
    end

    context "before the sixth failed attempt" do
      it "does not notify the organization admins" do
        expect(Decidim::EventsManager).not_to receive(:publish)

        manager.register_failed_attempt
      end
    end
  end

  describe "#register_success" do
    before do
      user.update(
        extended_data: {
          "authorizations" => {
            handler_key => { "failed_attempts" => 2, "locked_until" => 30.seconds.from_now.to_s },
            "some_other_handler" => { "foo" => "bar" }
          }
        }
      )
    end

    it "removes the lockout data for this handler" do
      manager.register_success

      expect(user.reload.extended_data.dig("authorizations", handler_key)).to be_nil
    end

    it "preserves lockout data belonging to other handlers" do
      manager.register_success

      expect(user.reload.extended_data.dig("authorizations", "some_other_handler")).to eq({ "foo" => "bar" })
    end
  end

  describe "#locked_indefinitely?" do
    context "when locked_until is infinite" do
      before do
        user.update(extended_data: { "authorizations" => { handler_key => { "locked_until" => "infinite" } } })
      end

      it "returns true" do
        expect(manager).to be_locked_indefinitely
      end
    end

    context "when locked_until is a timestamp" do
      before do
        user.update(
          extended_data: { "authorizations" => { handler_key => { "locked_until" => 30.seconds.from_now.to_s } } }
        )
      end

      it "returns false" do
        expect(manager).not_to be_locked_indefinitely
      end
    end

    context "when there is no lockout data" do
      it "returns false" do
        expect(manager).not_to be_locked_indefinitely
      end
    end
  end

  describe ".blocked_users" do
    let(:other_organization) { create(:organization) }

    let!(:locked_user) do
      create(:user, organization:,
                    extended_data: { "authorizations" => { handler_key => { "locked_until" => "infinite" } } })
    end
    let!(:softly_locked_user) do
      create(:user, organization:,
                    extended_data: { "authorizations" => { handler_key => { "locked_until" => 30.seconds.from_now.to_s } } })
    end
    let!(:unlocked_user) { create(:user, organization:) }
    let!(:locked_user_in_other_organization) do
      create(:user, organization: other_organization,
                     extended_data: { "authorizations" => { handler_key => { "locked_until" => "infinite" } } })
    end

    it "returns only the users of the given organization locked indefinitely" do
      expect(described_class.blocked_users(organization)).to contain_exactly(locked_user)
    end
  end
end
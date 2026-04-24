#encoding: utf-8
describe Session do

  describe ".scopes" do
    describe ".expired_sessions" do
      it "returns all the expired sessions " do
        expired_persistent_session = create(:expired_persistent_session)
        active_session = create(:persistent_session)
        expect(Session.expired_sessions).to eq([expired_persistent_session])
        Timecop.travel(10.days.from_now) do
          expect(Session.expired_sessions).to eq([expired_persistent_session, active_session])
        end
      end
    end
  end

  describe ".callback" do
    describe "not_stale" do
      it "returns true, when session record is not stale" do
        session = nil
        Timecop.travel(3.days.ago) do
          session = create(:persistent_session)
        end
        session.session_id = "asdfsdaf"
        expect(session.save).to be_truthy
      end

      it "returns false, when session record is stale" do
        session = create(:expired_persistent_session)
        expect(session.save).to be_falsey
      end
    end
  end

  describe "#lazy_touch" do
    it "touches the record when the last update is past by ttl_update_interval" do
     session = nil
      Timecop.travel(2.days.ago) do
        session = create(:persistent_session)
      end
      session.lazy_touch
      session.reload
      expect(session.updated_at.to_date).to eql(Date.today)
    end

    it " does not touch the session record when the last update is not past by ttl_update_interval" do
     session = nil
      Timecop.travel(3.hours.ago) do
        session = create(:persistent_session)
      end
      expected_updated_at = session.updated_at
      session.lazy_touch
      session.reload
      expect(session.updated_at.to_i).to eq(expected_updated_at.to_i)
    end
  end

  describe "#valid?" do
    it "returns true, when session_id is not stale" do
      session = create(:persistent_session)
      expect(session.valid?).to be_truthy
    end

    it "returns false, when session_id is stale" do
      session = create(:expired_persistent_session)
      expect(session.valid?).to be_falsey
    end
  end

  describe "#invalidate_ticket_and_destroy" do
    let(:session) { create(:persistent_session, service_ticket: 'TGT-somevalue') }
    let(:delete_url) { "#{UA_URL}/invalidate_service_ticket/#{session.service_ticket}" }

    before do
      stub_request(:delete, delete_url).
        to_return(:status => 200, :body => {}.to_json, :headers => {})
    end

    it "invalidates the cas service ticket" do
      session.invalidate_ticket_and_destroy
      expect(a_request(:delete, delete_url)).to have_been_made.once
    end

    it "destroys the session" do
      session.invalidate_ticket_and_destroy
      expect(Session.first).to be_nil
    end

    it 'uses a shared connection if provided' do
      connection = ConnectionHandler.connection(
        basic_auth: [
          Rails.configuration.ua_api_username,
          Rails.configuration.ua_api_password
        ],
        request_type: :json,
        uri: URI(UA_URL)
      )
      allow(connection).to receive(:run_request).and_call_original
      session.invalidate_ticket_and_destroy(connection)

      expect(connection).to have_received(:run_request).with(
        :delete, "/invalidate_service_ticket/#{session.service_ticket}", '', {}
      )
      expect(described_class.first).to be_nil
    end
  end
end

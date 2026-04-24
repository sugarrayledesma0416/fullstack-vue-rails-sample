require 'sidekiq/testing'

describe SessionAuditCleanerWorker do
  let(:cleaner) { described_class.new }

  before do
    # this record will not have a service_ticket, causing the process
    # to skip sending a request to UA, logic that is tested in the model spec.
    create(:expired_persistent_session)
  end

  describe '#perform' do
    it 'deletes sessions and invalidates cas tickets' do
      expect { cleaner.perform }.to change(Session, :count).by(-1)
    end

    it 'creates a shared connection to UA for processing all records' do
      connection = instance_double(Faraday)
      allow(ConnectionHandler).to receive(:connection).and_return(connection)
      expect_any_instance_of(Session).to receive(:invalidate_ticket_and_destroy)
        .with(connection).and_call_original

      cleaner.perform
    end
  end
end

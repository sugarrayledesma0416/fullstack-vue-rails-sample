describe Sidekiq::Persistence::ServerMiddleware do
  let(:middleware) { Sidekiq::Persistence::ServerMiddleware.new }

  describe '#call' do

    def stub_job(method)
      job = double('job', :running! => true, :delete => true)
      expect(job).to receive(method)
      allow(ScheduledJob).to receive(:find_by).and_return(job)
    end

    it 'sets the current job as running' do
      stub_job(:running!)
      middleware.call(nil, { jid: '1' }, nil) {}
    end

    it 'deletes the current job' do
      stub_job(:delete)
      middleware.call(nil, { jid: '1' }, nil) {}
    end

    it "deletes the current job even when an error occurs" do
      worker = ErrorWorker.new
      stub_job(:delete)
      expect do
        middleware.call(worker, { jid: '1' }, nil) { worker.perform(123, 'my name') }
      end.to raise_error('Fatal error test')
    end

    it "doesn't error if the job record doesn't exist" do
      allow(ScheduledJob).to receive(:find_by).and_return(nil)
      expect do
        middleware.call(nil, { jid: '2' }, nil) {}
      end.to_not raise_error
    end
  end

  describe "#check_health" do
    it "handles a disconnect error" do
      allow(ScheduledJob).to receive(:first).and_raise("Mysql2::Error: MySQL server has gone away")
      expect(ActiveRecord::Base.connection).to receive(:disconnect!)
      expect(ActiveRecord::Base).to receive(:establish_connection)
      expect { middleware.check_health }.to_not raise_error
    end

    it "raises an exception on any other error" do
      allow(ScheduledJob).to receive(:first).and_raise("Argh! Something's wrong!")
      expect { middleware.check_health }
        .to raise_error(RuntimeError, "Argh! Something's wrong!")
    end
  end

  class ErrorWorker
    def perform(id, name)
      [id, name]
      raise "Fatal error test"
    end
  end
end

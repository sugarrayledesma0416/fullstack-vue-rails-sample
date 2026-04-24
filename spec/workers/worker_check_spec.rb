describe WorkerCheck do
  let(:wargs) { [123, 456, 789] }
  let(:worker_class) { 'TestWorker' }
  let(:queue_name) { 'my_queue' }
  let(:worker)  { worker_class.constantize.new }
  let(:test_worker_data) do
    [
      "m3job2:21728:e619fd7978d0",
      "13jbm4",
      {
        "queue" => "default",
        "payload" =>
          {
            "class"=> worker_class,
            "args" => [],
            "retry" => false,
            "queue" => "default",
            "jid" => "208f3148c8d32d8f46322eec",
            "enqueued_at" => 1442323800.11212
          },
        "run_at" => 1442324703
      }
    ]
  end
  let(:old_test_worker_data) do
    test_worker_data.tap do |wd|
      wd[2]['payload']['jid'] = '208f3148c8d32d8f46322def'
    end
  end
  let(:conflicting_worker_data) do
    test_worker_data.tap do |wd|
      wd[2]['payload']['jid'] = '208f3148c8d32d8f46322def'
      wd[2]['payload']['class'] = 'ConflictingWorker'
    end
  end

  before do
    allow(Sidekiq::ScheduledSet).to receive(:new).and_return(
      [ double('SidekiqSchedSet', klass: worker_class, args: wargs) ]
    )
    allow(Sidekiq::Queue).to receive(:new).with(queue_name).and_return(
      [ double('SidekiqQueue', klass: worker_class, args: wargs) ]
    )
    allow(worker).to receive(:jid).and_return(test_worker_data[2]['payload']['jid'])
  end

  describe "#no_prior_process_running?" do
    it "returns true when the current process is the only one running" do
      allow(Sidekiq::Workers).to receive(:new).and_return([test_worker_data])
      expect(worker.no_prior_process_running?).to be_truthy
    end

    it "returns false when there is another process running"  do
      allow(Sidekiq::Workers).to receive(:new).and_return(
        [old_test_worker_data, test_worker_data]
      )
      expect(worker.no_prior_process_running?).to be_falsey
    end
  end

  describe '#identical_process_running?' do
    let(:test_worker_with_args_data) do
      test_worker_data.tap do |wd|
        wd[2]['payload']['jid'] = '208f3148c8d32d8f46322def'
        wd[2]['payload']['args'] = [123]
      end
    end
    let(:test_worker_with_matching_args_data) do
      test_worker_data.tap do |wd|
        wd[2]['payload']['jid'] = '308f3148c8d32d8f46322ghi'
        wd[2]['payload']['args'] = [123]
      end
    end
    let(:test_worker_with_different_args_data) do
      test_worker_data.tap do |wd|
        wd[2]['payload']['jid'] = '408f3148c8d32d8f46322jkl'
        wd[2]['payload']['args'] = [456]
      end
    end

    before do
      allow(worker).to receive(:jid).and_return(
        test_worker_with_args_data[2]['payload']['jid']
      )
    end

    it 'returns true when the worker class and args match' do
      allow(Sidekiq::Workers).to receive(:new).and_return(
        [test_worker_with_args_data, test_worker_with_matching_args_data]
      )
      expect(worker.identical_process_running?(123)).to be_truthy
    end

    it 'returns false when there is a mnatching worker with different args' do
      allow(Sidekiq::Workers).to receive(:new).and_return(
        [test_worker_with_args_data, test_worker_with_different_args_data]
      )
      expect(worker.identical_process_running?(123)).to be_falsey
    end

    it 'returns false if no matching workers are running' do
      allow(Sidekiq::Workers).to receive(:new).and_return(
        [test_worker_with_args_data]
      )
      expect(worker.identical_process_running?(123)).to be_falsey
    end
  end

  describe '#conflicting_process_running?' do
    it 'returns false when there are no conflicting jobs running' do
      allow(Sidekiq::Workers).to receive(:new).and_return([test_worker_data])
      expect(worker.conflicting_process_running?(ConflictingWorker)).to be_falsey
    end

    it 'returns true when there is a conflicting job running' do
      allow(Sidekiq::Workers).to receive(:new)
        .and_return([test_worker_data, conflicting_worker_data])
      expect(worker.conflicting_process_running?(ConflictingWorker)).to be_truthy
    end
  end

  describe "#worker_not_scheduled_or_queued?" do
    it "returns true when a worker is not scheduled or queued" do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return( [] )
      allow(Sidekiq::Queue).to receive(:new).and_return( [] )
      expect(worker.worker_not_scheduled_or_queued?(worker_class, queue_name, 123, 456)).to be_truthy
    end

    it "returns false when a worker is scheduled" do
      allow(Sidekiq::Queue).to receive(:new).and_return( [] )
      expect(worker.worker_not_scheduled_or_queued?(worker_class, queue_name, 123, 456)).to be_falsey
    end

    it "returns false when a worker is queued" do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return( [] )
      expect(worker.worker_not_scheduled_or_queued?(worker_class, queue_name, 123, 456)).to be_falsey
    end

    it "returns false when a worker is scheduled and queued" do
      expect(worker.worker_not_scheduled_or_queued?(worker_class, queue_name, 123, 456)).to be_falsey
    end
  end

  describe "#worker_queued?" do
    it "returns true when there is a worker queued and params match" do
      expect(worker.worker_queued?(worker_class, queue_name, 123, 456)).to be_truthy
    end

    it "return true when there is a worker queued and no params are passed" do
      expect(worker.worker_queued?(worker_class, queue_name)).to be_truthy
    end

    it "returns false when there is no matching worker queued" do
      allow(Sidekiq::Queue).to receive(:new).and_return( [] )
      expect(worker.worker_queued?(worker_class, queue_name, 123)).to be_falsey
    end

    it "returns false when the params don't match" do
      expect(worker.worker_queued?(worker_class, queue_name, 456)).to be_falsey
    end
  end

  describe "#worker_scheduled?" do
    it "returns true when there is a worker scheduled and params match" do
      expect(worker.worker_scheduled?(worker_class, 123)).to be_truthy
    end

    it "return true when there is a worker scheduled and no params are passed" do
      expect(worker.worker_scheduled?(worker_class)).to be_truthy
    end

    it "returns false when there is no matching worker scheduled" do
      allow(Sidekiq::ScheduledSet).to receive(:new).and_return( [] )
      expect(worker.worker_scheduled?(worker_class, 123)).to be_falsey
    end

    it "returns false when the params don't match" do
      expect(worker.worker_scheduled?(worker_class, 456)).to be_falsey
    end
  end

  describe "#params_match?" do
    let(:worker)  { worker_class.constantize.new }

    it "returns true when all params passed match worker params in order" do
      expect(worker.params_match?(wargs, [123])).to be_truthy
      expect(worker.params_match?(wargs, [123, 456])).to be_truthy
      expect(worker.params_match?(wargs, [123, 456, 789])).to be_truthy
    end

    it "returns true when nil is passed as one param and the others match in order" do
      expect(worker.params_match?(wargs, [123, nil, 789])).to be_truthy
    end

    it "returns false when a params does not match" do
      worker = TestWorker.new
      expect(worker.params_match?(wargs, [123, 457, 789])).to be_falsey
      expect(worker.params_match?(wargs, [123, nil, 780])).to be_falsey
    end

    it "returns false when params are out of order" do
      expect(worker.params_match?(wargs, [789, 456, 123])).to be_falsey
    end
  end
end

class TestWorker
  include WorkerCheck
end

class ConflictingWorker
  include WorkerCheck
end

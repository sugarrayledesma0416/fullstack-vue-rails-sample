describe ScheduledJob do
  let(:args) { ['one', 'two', 'three'] }
  let(:job) {
    ScheduledJob.create(
      :worker_class => 'TestWorker',
      :args => args) }
  let(:scheduled_datetime) { Time.at(1.hour.from_now.to_i).to_datetime } # a DateTime without microseconds
  let(:scheduled_job) {
    ScheduledJob.create(
      :worker_class => 'TestWorker',
      :args => args,
      :scheduled_for => scheduled_datetime.to_i ) }
  let(:queued_jobs) { ScheduledJob.queued }
  let(:running_jobs) { ScheduledJob.running }

  class TestWorker
    include Sidekiq::Worker
  end

  before do
    allow(TestWorker).to receive(:perform_async).and_return(true)
    allow(TestWorker).to receive(:perform_at).and_return(true)
  end

  context 'when a args is saved as an array' do
    it 'is properly serialized, stored, and deserialized' do
      job # queue a job
      expect(queued_jobs.first.args).to eq(args)
    end
  end

  describe 'scopes' do
    describe '#running' do
      it 'returns all running jobs' do
        job.running!
        expect(running_jobs).to include(job)
      end
    end

    describe '#queued' do
      it 'returns all queued jobs' do
        expect(queued_jobs).to include(job)
      end
    end
  end

  describe '#running!' do
    it 'flags the job as having started' do
      job.running!
      expect(job.started).to be_truthy
    end
  end

  describe '#requeue!' do
    it 'requeues all pending jobs' do
      job # queue a job
      expect(TestWorker).to receive(:perform_async).with(*job.args)
      ScheduledJob.requeue!
    end

    it "reschedules scheduled jobs" do
      scheduled_job # schedule a job
      expect(TestWorker).to receive(:perform_at).with(scheduled_datetime, *job.args)
      ScheduledJob.requeue!
    end

    context 'when a job has started' do
      it 'does not get requeued' do
        job.running!
        expect(TestWorker).not_to receive(:perform_async)
        ScheduledJob.requeue!
      end
    end
  end

  describe '#requeue' do
    it "requeues the job" do
      job # queue a job
      expect(TestWorker).to receive(:perform_async).with(*job.args)
      sch_job = ScheduledJob.last
      sch_job.requeue
    end

    it "doesn't requeue the job if it's running" do
      job.running!
      expect(TestWorker).not_to receive(:perform_async)
      sch_job = ScheduledJob.last
      sch_job.requeue
    end
  end
end

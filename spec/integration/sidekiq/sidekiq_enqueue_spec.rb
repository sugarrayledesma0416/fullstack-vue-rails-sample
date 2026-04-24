require 'sidekiq/testing'

# The #drain test method does not hit the server middleware.
# Because of this, server middleware needs to be tested via an integration test,
# which is hard to write. Use sidekiq_server.rb to run a test job.

# To run any jobs, make sure Redis and Sidekiq are both running,
# and that the queue name is defined in sidekiq.yml.

# fake! => jobs are pushed onto a #jobs array
# inline! => jobs run immediately
# disable! => jobs are pushed to Redis
Sidekiq::Testing.fake!

describe 'sidekiq enqueue' do
  class TestWorker
    include Sidekiq::Worker
    include Sidekiq::Status::Worker

    sidekiq_options retry: false

    def perform(id, name)
      [id, name]
    end
  end

  context 'when a new test job has been enqueued' do
    let(:job) { ScheduledJob.queued.first }

    before do
      Sidekiq::Worker.clear_all
      TestWorker.perform_async(1, 'Test')
    end

    # undefined method `has_queued_job?' for TestWorker:Class
    xit 'enqueues a new job', test_debt: true do
      expect(TestWorker).to have_queued_job(1)
    end

    it 'creates a database record' do
      expect(ScheduledJob.queued.size).to eq(1)
    end

    it 'stores the worker class name' do
      expect(job.worker_class).to eq('TestWorker')
    end

    it 'stores the args passed to the job' do
      expect(job.args).to eq([1, 'Test'].to_json)
    end

    it 'sets the started flag to false' do
      expect(job.started).to eq(false)
    end
  end
end

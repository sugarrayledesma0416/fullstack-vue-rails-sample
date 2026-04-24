describe Sidekiq::Persistence::ClientMiddleware do
  let(:middleware) { Sidekiq::Persistence::ClientMiddleware.new }

  describe '#call' do
    it 'creates a scheduled job record' do
      expect(ScheduledJob).to receive(:find_or_create_by)
      middleware.call(nil, {}, nil) {}
    end

    it 'saves the scheduled timestamp to the ScheduledJob model when present' do
      job_params = {
        "class"=>"GradebookUpdaterWorker",
        "args" => [],
        "at" => 1406313005.2683597,
        "jid" => "b30b45d45535532850ad2b13",
        "enqueued_at" => 1406312129.2713017
      }
      middleware.call(nil, job_params, nil) {}
      expect(ScheduledJob.last.scheduled_for).to eq job_params['at'].to_i
    end

    it 'saves the worker arguments to the ScheduledJob model' do
      job_params = {
        "class"=>"BulkAssignmentWorker",
        "args" => [[93], 
                   64, 
                   {"04/11/2019"=>[{"id"=>42223, "group_id"=>3, "category"=>"Homework"}, {"id"=>42224, "group_id"=>3, "category"=>"Homework"}]}, 
                   {"Homework"=>{"name"=>"Homework", "weighting_percent"=>100, "has_assignments"=>true, "rank"=>1, "penalty_percent"=>5, "late_work_penalty"=>"percent_per_day", "max_attempts"=>2, "credit_only"=>false, "enhanced_feedback_disabled"=>false, "accept_late_work"=>true, "drop_low_scores"=>0}}
                  ],
        "at" => 1406313005.2683597,
        "jid" => "b30b45d45535532850ad2b13",
        "enqueued_at" => 1406312129.2713017
      }
      middleware.call(nil, job_params, nil) {}
      expect(ScheduledJob.last.args).to eq(job_params['args'].to_json)
    end
  end
end

module WorkerCheck

  # These 3 methods are a bit racy, checking Sidekiq::Workers for a running
  # worker with a particular class name. The process you are looking for
  # could complete while we're in the process of checking or if more than
  # one job of the same type are started very close together.

  # The Sidekiq::Workers object has an asynchronous polling cycle of 5 seconds.
  # Under normal circumstances, jobs that we want to run only one of will not
  # get started rapidly except if jobs are not being processed normally and
  # they start to back up in the queue. If this situation persists long enough
  # for more than one job of this type to get queued, we may end up with
  # multiple jobs starting within a five second period.
  def no_prior_process_running?
    # find all jobs running of the same class ignoring the current job id
    Sidekiq::Workers.new.none? do |_pid, _tid, worker|
      payload = worker['payload']
      payload['class'] == self.class.name && payload['jid'] != self.jid
    end
  end

  # detects an identical job running w/ identical args
  # ignores current job id
  def identical_process_running?(*args)
    Sidekiq::Workers.new.any? do |_pid, _tid, worker|
      payload = worker['payload']
      payload['class'] == self.class.name &&
        payload['jid'] != self.jid &&
        params_match?(payload['args'], args)
    end
  end

  # detects another job running that the current worker could conflict with
  def conflicting_process_running?(worker_class)
    Sidekiq::Workers.new.any? do |_pid, _tid, worker|
      worker['payload']['class'] == worker_class.to_s
    end
  end

  # Use this sparingly.
  # Returns the thread_id for the process running this job
  # Use as a logstash attribute to graph jobs by workers
  # Most useful in analyzing section update processing
  def thread_id
    if self.jid
      Sidekiq::Workers.new.detect do |_pid, _tid, worker|
        worker['payload']['jid'] == self.jid
      end.second
    end
  end

  def worker_not_scheduled_or_queued?(worker_class, queue_name, *args)
    !(worker_scheduled?(worker_class, *args) || worker_queued?(worker_class, queue_name, *args))
  end

  # returns true if there is a job of worker_class scheduled
  def worker_scheduled?(worker_class, *args)
    scheduled_items.any? { |w| w.klass == worker_class && params_match?(w.args, args) }
  end

  # Very racy. The amount of time jobs are in the queue is normally extremely small.
  # This could be used to prevent a job from running its task during recovery from
  # a queue backlog but those cases are rare.
  # return true if there is a job of worker_class in the queue with no errors.
  def worker_queued?(worker_class, queue_name, *args)
    queue_items(queue_name).any? { |w| w.klass == worker_class && params_match?(w.args, args) }
  end

  def scheduled_items
    @scheduled_items ||= Sidekiq::ScheduledSet.new
  end

  def queue_items(queue_name)
    @queued_items ||= Sidekiq::Queue.new(queue_name)
  end

  def params_match?(worker_args, match_args)
    # args must all match in the same order
    worker_args.each_with_index do |wargs, idx|
      next if match_args[idx].nil?  # nil means we don't care
      break if wargs != match_args[idx]
    end
  end
end

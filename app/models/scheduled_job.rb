class ScheduledJob < ApplicationRecord
  scope :running, -> { where(started: true) }
  scope :queued, -> { where(started: false) }

  serialize :args

  def running!
    self[:started] = true
    save
  end

  # requeues all pending jobs
  # use to recover from redis failure
  def self.requeue!
    queued.each do |job|
      job.delete # the record gets recreated
      worker = job.worker_class.constantize

      if job.scheduled_for
        worker.perform_at(Time.at(job.scheduled_for).to_datetime, *job.args)
      else
        worker.perform_async(*job.args)
      end
    end
  end

  # requeue this job if not running
  def requeue
    unless started
      self.delete # the record gets recreated
      worker = self.worker_class.constantize
      worker.perform_async(*self.args)
    end
  end
end

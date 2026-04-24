# Finds courses whose end date falls within a date range and schedules
# jobs to prune scores for them.
class GradebookPruneScoresSchedulerWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  def perform(
    end_date_min = (Time.zone.today - 1.years).to_s,
    end_date_max = (Time.zone.today - 1.years).to_s
  )
    logger_data_merge(
      end_date_min: end_date_min,
      end_date_max: end_date_max
    )
    course_ids = Course.where('end_date BETWEEN ? AND ?', end_date_min, end_date_max)
                       .pluck(:id)
    course_ids.each_with_index do |course_id, i|
      # Space the jobs out by 30 seconds each to limit pressure on the
      # database in the event of a large number of courses being
      # pruned.
      GradebookPruneScoresWorker.perform_in(i * 30, course_id)
    end
  end
end

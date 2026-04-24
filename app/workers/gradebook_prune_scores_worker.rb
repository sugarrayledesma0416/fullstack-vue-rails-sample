class GradebookPruneScoresWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  def perform(course_id)
    logger_data_merge(
      course_id: course_id
    )
    GradebookEngine::GradebookAPI.prune_scores(course_id)
  end
end

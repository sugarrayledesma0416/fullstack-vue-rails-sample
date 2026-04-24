class GradebookDeleteScoresWorker
  include Sidekiq::Worker
  include WorkerInstrumentation

  def perform(course_id)
    logger_data_merge(
      course_id: course_id
    )
    GradebookEngine::GradebookAPI.delete_scores(course_id)
  end
end


module Gradebook
  # Submits a student's grade to the gradebook in a transaction safe way.
  class Submission
    def initialize(student, section, activity)
      @student = student
      @section = section || Section.section_zero
      @activity = activity
    end

    def submit(results, submitted_at = Time.zone.now, time_spent = 0, submission_length = nil)
      if @activity.is_a? Activity
        if @activity.content_object&.credit_only?
          points_possible = results.total_points_possible
          points_earned = points_possible.to_f
          pending = false
        else
          points_possible = results.total_points_possible
          points_earned = (results.score * points_possible).round
          pending = results.instructor_graded_score_pending?
        end
      else
        points_possible = results[:points_possible]
        points_earned = results[:points_earned]
        pending = false
      end

      submit_points(
        count_attempt: true,
        gradable: @activity.gradable?,
        pending: pending,
        points_earned: points_earned,
        points_pending: (pending ? results.instructor_graded_points_possible : 0),
        points_possible: points_possible,
        submission_length: submission_length,
        submitted_at: submitted_at,
        time_spent: time_spent
      )
    end

    def submit_nongradable(time_spent = 0, submitted_at = Time.zone.now)
      raise 'submit_nongradable can only called for activities that are non-gradable' if @activity.gradable?

      submit_points(
        gradable: false,
        pending: false,
        points_earned: 1.0,
        points_possible: 1,
        submission_length: nil,
        submitted_at: submitted_at,
        time_spent: time_spent
      )
    end

    def submit_points(params)
      %i(points_possible points_earned pending submitted_at time_spent gradable).each do |key|
        raise "#{key} param required" if params[key].nil?
      end

      update_gradebook(score_params(params, current_score))

      # return current grade
      GradebookEngine::GradebookAPI.find_student_grade(user_id: @student.id,
                                                       section_id: @section.id,
                                                       activity_id: @activity.id)
    end

    def update_gradebook(params)
      # We should not create score actions for section zero.
      unless @section.zero?
        # Use the value in the params, if it's missing use the one from the
        # previous score action for the student, section, and activity
        settings = {
          points_earned: params[:points_earned],
          points_pending: params[:points_pending],
          pending: params[:pending],
          points_possible: params[:points_possible],
          time_spent: params[:time_spent],
          submitted_at: params[:submitted_at],
          attempt_count: attempt_count
        }
        settings.merge!(partial_pending: params[:partial_pending]) if params.key?(:partial_pending)
        settings.merge!(completed_subactivities_count: params[:completed_subactivities_count]) if params.key?(:completed_subactivities_count)
        settings.merge!(subactivities_count: params[:subactivities_count]) if params.key?(:subactivities_count)
        GradebookEngine::GradebookAPI.submit(
          @student.id, @section.id, @activity.id, @section.school_id,
          settings)
      end
    end

    private def current_score
      # fetch the latest score action
      # returns nil if not found
      GradebookEngine::GradebookAPI.find_score(user_id: @student.id,
                                               section_id: @section.id,
                                               activity_id: @activity.id)
    end

    private def attempt_count
      Attempt.by_student_section_and_activity(@student, @section, @activity)
             .pluck(:attempt_number)
             .first
    end

    private def score_params(submitted_params, score)
      params = submitted_params.dup

      # use score.submitted_at when assignment is not gradable and already submitted
      # we only care about the first view time.
      if !params[:gradable] && score && score.submitted_at.present?
        params[:submitted_at] = score.submitted_at
      end

      # points_pending should be 0 if pending is false
      unless !!params[:pending]
        params[:points_pending] = 0
      end

      params
    end

    def create_demo_score(attempt, submitted_at)
      if @activity.gradable?
        submit(attempt.results, submitted_at, attempt.time_spent, attempt.submission_length) if attempt.submitted_or_completed?
      else
        submit_nongradable(attempt.time_spent, submitted_at)
      end
    end
  end
end


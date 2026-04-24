module AI
  module InstructorGrading
    class SuggestionRatingDetailPresenter < SuggestionRatingReportsQuestionPresenter
      attr_reader :program, :activity, :instructor, :page

      PER_PAGE = 1

      def initialize(program:, activity:, instructor:, page: 1)
        @program = program
        @activity = activity
        @instructor = instructor
        @page = page.to_i
        @attempt_ids = fetch_attempt_ids
      end

      def total_pages
        @total_pages ||= (@attempt_ids.size.to_f / PER_PAGE).ceil
      end

      def current_page
        @page.clamp(1, total_pages)
      end

      def next_page
        current_page < total_pages ? current_page + 1 : nil
      end

      def previous_page
        current_page > 1 ? current_page - 1 : nil
      end

      def current_attempt_id
        @attempt_ids[(current_page - 1) * PER_PAGE]
      end

      def current_attempt
        @current_attempt ||= Attempt.find_by(id: current_attempt_id)
      end

      def current_question
        @current_question ||= begin
          if activity_type_is_open_ended?
            questions.detect { |question| question.rank == current_page }
          else
            questions.first
          end
        end
      end

      def student_response(question)
        return unless current_attempt
        full_sanitizer(current_attempt.results.response(question&.label))
      end

      def full_sanitizer(html)
        ActionView::Base.full_sanitizer.sanitize(html)
      end

      def current_suggestion_rating
        @current_suggestion_rating ||= AI::SuggestionRatingDetail.find_by(
          activity_id: activity.id,
          attempt_id: current_attempt_id
        )
      end

      def current_grading_suggestions
        @current_grading_suggestions ||= begin
          query = AI::GradingSuggestion.where(activity_id: activity.id, attempt_id: current_attempt_id)
          query = query.where(question_label: current_question.label) if activity_type_is_open_ended?
          query
        end
      end

      def current_overall_comments
        @current_overall_comments ||= begin
          query = AI::OverallComment.where(activity_id: activity.id, attempt_id: current_attempt_id)
          query = query.where(question_label: current_question.label) if activity_type_is_open_ended?
          query
        end
      end


      def activity_type_is_composition?
        @activity_type_is_composition ||= activity.composition?
      end

      def activity_type_is_open_ended?
        @activity_type_is_open_ended ||= activity.open_ended?
      end

      def questions
        @questions ||= activity.questions
      end

      private def fetch_attempt_ids
        suggestion_rating_details_sql = AI::SuggestionRatingDetail
          .where(activity_id: activity.id, updated_by_id: instructor.id)
          .select(:attempt_id)
          .to_sql

        grading_suggestions_sql = AI::GradingSuggestion
          .includes(:rating_category, :prompt)
          .where(activity_id: activity.id, rated_by_id: instructor.id)
          .select(:attempt_id)
          .to_sql

        overall_comments_sql = AI::OverallComment
          .includes(:rating_category, :prompt)
          .where(activity_id: activity.id, rated_by_id: instructor.id)
          .select(:attempt_id)
          .to_sql

        AI::SuggestionRatingDetail
          .find_by_sql("#{suggestion_rating_details_sql} UNION #{grading_suggestions_sql} UNION #{overall_comments_sql}")
          .pluck(:attempt_id)
          .sort
          .reverse
      end
    end
  end
end

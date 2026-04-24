module AI
  module InstructorGrading
    class SuggestionRatingReportsController < ApplicationController
      MAX_RESULT_COUNT_ON_PAGE_LOAD = 10
      MAX_RESULT_COUNT_ON_BACKGROUND_LOAD = 20

      before_action :require_user
      before_action :set_current_focus

      layout 'music_v1/default'

      def index
        authorize! :index, self.class

        @page_title = 'Flagged Suggestions by Instructors'

        @presenter = AI::InstructorGrading::SuggestionRatingReportsPresenter.new(
          activity_type: params[:selected_types],
          grading_suggestion_prompt:,
          overall_comment_prompt:,
          program:,
          lesson_ids: params[:selected_lesson_ids],
          selected_strands: params[:selected_strands],
          selected_instructors: params[:selected_instructor_ids],
          req_params: params
        )
      end

      def show
        authorize! :show, self.class

        respond_to do |format|
          format.json do
            @presenter = AI::InstructorGrading::SuggestionRatingReportsQuestionPresenter.new(
              activity: Activity.find(params[:activity_id]),
              grading_suggestion_prompt:,
              limit: MAX_RESULT_COUNT_ON_BACKGROUND_LOAD,
              offset: params[:offset],
              overall_comment_prompt:,
              question_rank: params[:question_rank].to_i
            )

            render json: {
              entries: @presenter.entries,
              nextUrl: @presenter.load_more_url
            }
          end

          format.html do
            @presenter = AI::InstructorGrading::SuggestionRatingDetailPresenter.new(
              program:,
              activity: Activity.find(params[:activity_id]),
              instructor: Instructor.find(params[:instructor_id]),
              page: params[:page] || 1
            )
          end

          format.any { head :unsupported_media_type }
        end
      end

      private def program
        @program ||= Program.find(params[:program_id])
      end

      private def grading_suggestion_prompt
        if params[:grading_suggestion_prompt_id].present?
          AI::GradingSuggestionPrompt.find(params[:grading_suggestion_prompt_id])
        end
      end

      private def overall_comment_prompt
        if params[:overall_comment_prompt_id].present?
          AI::OverallCommentPrompt.find(params[:overall_comment_prompt_id])
        end
      end

      private def attempt
        if params[:attempt_id].present?
          Attempt.find(params[:attempt_id])
        end
      end
    end
  end
end

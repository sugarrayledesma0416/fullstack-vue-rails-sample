module AI
  module LiveData
    class GradingInputsController < ApplicationController
      before_action :require_user

      layout 'music_v1/default'

      def index
        authorize! :index, self.class

        respond_to do |format|
          format.json do
            @presenter = AI::LiveData::GradingInputsPresenter.new(
              program:,
              filter: filter_params,
              start_time:,
              end_time:,
              offset: params[:offset],
              limit: 20
            )

            render json: {
              entries: @presenter.entries,
              nextUrl: @presenter.load_more_url
            }
          end

          format.html do
            @presenter = AI::LiveData::GradingInputsPresenter.new(
              program:,
              filter: filter_params,
              start_time:,
              end_time:,
              offset: 0,
              limit: 0
            )
            @page_title = 'Grading suggestion inputs from Live'
          end

          format.any { head :unsupported_media_type }
        end
      end

      def create
        authorize! :create, self.class

        respond_to do |format|
          format.json do
            validator = AI::LiveData::GradingInputValidator.new(
              attempt: Attempt.find(params[:attempt_id]),
              question_label: params[:question_label]
            )
            if validator.valid?
              input = AI::GradingSuggestionInput.new(
                program_id: program.id,
                activity_id: validator.activity.id,
                attempt_id: validator.attempt.id,
                question_label: validator.question.label,
                student_response: validator.response
              )
              if input.save
                AI::GradingSuggestionGenerators::AsyncQuestionGenerator.new(
                  attempt: validator.attempt,
                  question_label: validator.question.label,
                  grading_suggestion_input: input
                ).generate
                AI::OverallCommentGenerators::AsyncQuestionGenerator.new(
                  attempt: validator.attempt,
                  question_label: validator.question.label,
                  grading_suggestion_input: input
                ).generate

                render json: { id: input.id }
              else
                render json: { errors: input.errors.full_messages }, status: :bad_request
              end
            else
              render json: { errors: validator.errors }, status: :bad_request
            end
          end

          format.any { head :unsupported_media_type }
        end
      end

      private def program
        @program ||= Program.find(params[:program_id])
      end

      private def filter_params
        {
          activity_type: params[:activity_type]
        }
      end

      private def start_time
        @start_time ||= if params[:start_date].present?
                          DateTime.parse(params[:start_date])
                        else
                          1.day.ago
                        end.beginning_of_day
      end

      private def end_time
        @end_time ||= if params[:start_date].present? && params[:end_date].present?
                        DateTime.parse(params[:end_date])
                      else
                        start_time + 1.day
                      end.end_of_day
      end
    end
  end
end

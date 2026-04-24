module AI
  module LiveData
    class GradingInputRatingReportsController < ApplicationController
      before_action :require_user

      layout 'music_v1/default'

      def index
        authorize! :index, self.class

        @page_title = 'Internal Grading Suggestions & Overall Comments with Negative Ratings'

        @presenter = AI::LiveData::GradingInputRatingReportsPresenter.new(program:)
      end

      def show
        authorize! :show, self.class

        @page_title = 'Internal Grading Suggestions & Overall Comments with Negative Ratings'

        @presenter = AI::LiveData::GradingInputRatingReportsQuestionPresenter.new(
          activity: Activity.find(params[:activity_id]),
          question_rank: params[:question_rank].to_i
        )
      end

      private def program
        @program ||= Program.find(params[:program_id])
      end
    end
  end
end

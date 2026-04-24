module AI
  module LiveData
    class GradingInputRatingsController < ApplicationController
      before_action :require_user

      layout 'music_v1/default'

      def index
        authorize! :index, self.class

        @presenter = AI::LiveData::GradingInputRatingsPresenter.new(
          include_rated_inputs:,
          program:,
          rater: current_user,
          req_params: params
        )
      end

      def rate_question
        authorize! :rate_question, self.class

        @presenter = AI::LiveData::GradingInputRatingsQuestionPresenter.new(
          activity: Activity.find(params[:activity_id]),
          include_rated_inputs:,
          question_rank: params[:question_rank].to_i,
          rater: current_user
        )
      end

      private def include_rated_inputs
        ActiveModel::Type::Boolean.new.cast(params[:include_rated_inputs])
      end
    end
  end
end

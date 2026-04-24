module AI
  module LiveData
    class OverallCommentPromptsController < ApplicationController
      before_action :require_user

      layout 'music_v1/default'

      def index
        authorize! :index, self.class

        @presenter = AI::LiveData::OverallCommentPromptsPresenter.new(
          program:,
          comparison_prompt_ids: params[:comparison_prompt_ids]
        )
      end

      private def program
        @program ||= Program.find(params[:program_id])
      end
    end
  end
end

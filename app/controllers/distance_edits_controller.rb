class DistanceEditsController < ApplicationController
  before_action :require_user

  def create
    results = check_answer(params[:target], params[:student_response])
    render json: results
  end

  def serializer
    MaestroActivityEngine::ActivityContent::WolCorrectness::InstantFeedback::CorrectionEditSerializer
  end

  private def check_answer(target, student_response)
    serializer.serialized_correction_edits(target, student_response)
  end
end

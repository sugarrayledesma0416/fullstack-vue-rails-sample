class QuestionToGradeViewManager
  include GradingSetQuestionViewLogic
  include TableActivityLogic

  delegate :current_student, :current_student_attempt, :composition_attachment,
           :activity_composition?, :to => :presenter

  def initialize(presenter, question)
    super(presenter, question)
  end

  def current_response_id
    response_id(current_student, question)
  end

  def column_matching_question?
    question.is_a?(MaestroActivityEngine::ActivityContent::ColumnMatching::Item)
  end

  def is_solo_video_recording_question?
    question.is_a?(MaestroActivityEngine::ActivityContent::SoloVideoRecording::Item)
  end

  def feedback_has_inline_corrections?
    feedback[current_response_id] && feedback[current_response_id].inline_corrections
  end

  def current_question_is_virtual_chat_type?
    question.is_a? MaestroActivityEngine::ActivityContent::VirtualChat::Item
  end

  def current_question_is_partner_chat_type?
    question.is_a?(MaestroActivityEngine::ActivityContent::PartnerChat::Item)
  end

  def html_friendly_prompt
    question.html_friendly_prompt do
      reference = activity.content_object.items.detect{ |item| item.is_a?(MaestroActivityEngine::ActivityContent::Reference::Base) }
      yield :format_reference, reference
    end
  end

  def feedback_attachment
    feedback[current_response_id] && feedback[current_response_id].composition_attachment
  end

  def has_student_attachment?
    presenter.has_student_attachment_for?(question)
  end
end

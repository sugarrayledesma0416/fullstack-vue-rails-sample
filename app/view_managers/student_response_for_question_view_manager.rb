class StudentResponseForQuestionViewManager
  include ActionView::Helpers::TextHelper
  include TableActivityLogic

  delegate :program, to: :activity

  attr_accessor :activity, :attempt, :editor_index, :feedback_item, :grading_suggestion_data,
                :instructor, :instructor_comment_recording_path, :is_new_recording,
                :params, :question, :response_id, :student

  def initialize(activity:, attempt:, editor_index:, feedback_item:, grading_suggestion_data:,
                 instructor:, instructor_comment_recording_path:, is_new_recording:,
                 params:, question:, response_id:, student:)
    self.activity = activity
    self.student = student
    self.attempt = attempt
    self.question = question
    self.response_id = response_id
    self.feedback_item = feedback_item
    self.instructor = instructor
    self.grading_suggestion_data = grading_suggestion_data
    self.instructor_comment_recording_path = instructor_comment_recording_path
    self.is_new_recording = is_new_recording
    self.editor_index = editor_index
    self.params = params
  end

  def question_number
    question.question_number
  end

  private def question_label
    @question_label ||=
      if question.is_a?(MaestroActivityEngine::ActivityContent::TrueFalseEnhanced::Item)
        "#{question.label}_correction"
      else
        question.label
      end
  end

  def results
    # results_for_question ignores the argument and returns all results
    @results ||= attempt.results_for_question(question.label)
  end

  def section_attempt
    @section_attempt ||= attempt.section
  end

  def attempt_activity
    @attempt_activity ||= attempt.activity
  end

  def response
    results.response(question_label) if attempt && results.has_response?(question_label)
  end

  def has_valid_response?
    response.present? && strip_tags(response.gsub(/(&nbsp;| |\r\n)/m, '')).present?
  end

  def inline_corrections
    return @inline_corrections if defined? @inline_corrections
    @inline_corrections = params[inline_corrections_field] ||
                          feedback_item&.inline_corrections ||
                          (attempt && response) ||
                          (!composition_question? && '') ||
                          nil
  end

  def attachment
    return @attachment if defined? @attachment
    @attachment = results.attachment_for(question.label)
  end

  def has_attachment?
    attachment.present?
  end

  def inline_corrections_field
    "inline_corrections_for_#{response_id}"
  end

  def show_student_response_link?
    feedback_item&.inline_corrections && !recording_question?
  end

  def composition_question?
    question.is_a?(MaestroActivityEngine::ActivityContent::Composition::Item)
  end

  def smartbook_question?
    question.is_a?(Smartbook::Response)
  end

  def smartbook_audio_recording_question?
    smartbook_question? && question.question_type == 'voice_recording'
  end

  def smartbook_matching_question?
    smartbook_question? && question.question_type == 'matching'
  end

  def smartbook_drawing_question?
    smartbook_question? && question.question_type == 'drawing'
  end

  def smartbook_response
    if smartbook_question? && results.has_response?(question.label)
      results.result(question.label)[:smartbook_response]
    end
  end

  def recording_question?
    question.is_a?(MaestroActivityEngine::ActivityContent::Recording::Question)
  end

  def solo_video_recording_question?
    question.is_a?(MaestroActivityEngine::ActivityContent::SoloVideoRecording::Item)
  end

  def ai_virtual_chat_question?
    question.is_a?(MaestroActivityEngine::ActivityContent::AIVirtualChat::Item)
  end

  def grading_options
    @grading_options ||= AI::SuggestionRatingCategory.where(internal_use: false).map do |o|
      { id: o.id, label: o.label }
    end.to_json
  end

  def student_section_config
    @student_section_config ||= begin
      config = StudentSectionConfig.where(section_id: section_attempt.id, user_id: student.id)
      config.present? ? config.first : {}
    end
  end

  def score_controls_view_manager
    ScoreControlsViewManager.new(
      question,
      feedback_item,
      smartbook_question? ? smartbook_response : results,
      response_id,
      params
    )
  end

  def feedback_elm_id
    "student_response_#{response_id}_feedback"
  end

  def mount_ai_grading_app?
    return false unless activity.supports_ai_grading_feature?

    ai_grading_feature_enabled? || ai_grading_suggestions.present? || ai_overall_comment.present?
  end

  def ai_grading_feature_enabled?
    program.ai_grading_feature_enabled? || instructor.can_use_ai_grading_suggestions?
  end

  def ai_grading_suggestions
    # TODO: Optimize that to not make one query per attempt and per quetion.
    @ai_grading_suggestions ||= AI::GradingSuggestion.non_internal.where(
      attempt_id: attempt.id,
      question_label: question.label
    )
  end

  def serialized_ai_grading_suggestions
    grading_suggestion_data[:suggestions].map do |suggestion|
      {
        accepted: suggestion.accepted?,
        edited: suggestion.edited?,
        error_explanation: suggestion.error_explanation,
        id: suggestion.id,
        incorrect_text: suggestion.incorrect_text,
        incorrect_text_begin_offset: suggestion.incorrect_text_begin_offset,
        incorrect_text_end_offset: suggestion.incorrect_text_end_offset,
        rating_category_id: suggestion.rating_category_id,
        rating_comment: suggestion.rating_comment,
        rejected: suggestion.rejected?
      }
    end
  end

  def serialized_ai_grading_suggestion_job
    grading_suggestion_data[:suggestion_job]&.attributes&.symbolize_keys || {}
  end

  def ai_overall_comment
    return @ai_overall_comment if defined? @ai_overall_comment

    @ai_overall_comment = AI::OverallComment.non_internal.find_by(
      attempt_id: attempt.id,
      question_label: question.label
    )
  end

  def serialized_ai_overall_comment
    comment = ai_overall_comment

    if comment.present?
      {
        accepted: comment.accepted?,
        edited: comment.edited?,
        explanation: comment.explanation,
        id: comment.id,
        overall_comment: comment.overall_comment,
        rating_category_id: comment.rating_category_id,
        rating_comment: comment.rating_comment,
        rejected: comment.rejected?
      }
    end
  end

  def serialized_ai_rating_categories
    AI::SuggestionRatingCategory.non_internal.all.map do |category|
      {
        id: category.id,
        label: category.label,
        description: category.description
      }
    end
  end

  def serialized_ai_rating_details
    details = AI::SuggestionRatingDetail.find_by(
      attempt:,
      question_label: question.label
    )

    if details.present?
      {
        comment: details.comment
      }
    end
  end

  def ai_rating_default_category
    AI::SuggestionRatingCategory.non_internal.find_by!(label: 'other').id
  end

  def comment_elm_id
    "comment_for_#{response_id}"
  end

  def ai_grading_suggestions_hidden_form_elm_name
    "ai_grading_suggestions_for_#{response_id}"
  end

  def ai_overall_comment_hidden_form_elm_name
    "ai_overall_feedback_for_#{response_id}"
  end

  def ai_rating_details_hidden_form_elm_name
    "ai_suggestion_rating_details_for_#{response_id}"
  end
end

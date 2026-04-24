class StudentGradingSubmission
  include AutoGradedQuestionCheckable

  INSTRUCTOR_MARKUP_TAGS = %w[
    data-tracking
    instructor_comment
    instructor_addition
    instructor_deletion
    recording_decor
    data-comment-inline
  ].freeze

  attr_reader(
    :activity,
    :attempt,
    :concurrent_enrollment_ai_bug_detected,
    :feedback_notification_sent,
    :grading_feedback,
    :instructor,
    :params,
    :question,
    :student
  )

  def initialize(
    activity:,
    attempt:,
    grading_feedback:,
    instructor:,
    params:,
    question:,
    student:
  )
    @params = params
    @student = student
    @question = question
    @attempt = attempt
    @activity = activity
    @instructor = instructor
    @grading_feedback = grading_feedback
    @feedback_notification_sent = false
    @concurrent_enrollment_ai_bug_detected = false
  end

  def valid?
    return true if points_earned.blank? # blank scores are ok

    points_earned_valid?
  end

  def feedback_notification_sent?
    feedback_notification_sent
  end

  def score_field
    score_key
  end

  def submit
    # It is possible that the student is actually an instructor. For
    # example, it is possible for instructors to do partner chat
    # activities with students and thus end up here in the grading
    # submission. When that happens, we will ignore them.
    return if student.instructor? || grading_feedback.attempt_for_student(student).nil?

    # Detect concurrent enrollment bug before any processing
    ce_bug_detected = ai_grading_enabled? && !attempt_matches_ai_grading_params?

    # If CE bug is detected, set flag and skip transaction
    if ce_bug_detected
      @concurrent_enrollment_ai_bug_detected = true
      return
    end

    # Only process AI and transaction if no CE bug detected
    if ai_grading_enabled? && attempt_matches_ai_grading_params?
      validate_ai_grading_params
      # Check for any inconsistency between the submitted parameters
      check_for_ai_grading_use_inconsistency
    end

    RubricCriteriaScore.transaction do
      if rubric_graded_and_submittable?(params[:criteria])
        RubricCriteriaScore.submit(
          activity:,
          criteria: params[:criteria],
          section:,
          student:
        )
      end

      ai_comments_params = if attempt_matches_ai_grading_params?
                             feedback_item_ai_comments_params
                           else
                             {}
                           end
      FeedbackItem.submit(
        feedback_params.merge(
          feedback_item_ai_comments: ai_comments_params
        )
      )
    end

    if ai_grading_enabled? && attempt_matches_ai_grading_params?
      update_ai_overall_comments
      update_ai_grading_suggestions
      update_ai_suggestion_rating_details
    end

    true
  end

  # Returns true if the AI grading is enabled. This is based on the activity type.
  # It was previously based on that feature being enabled at the program level
  # or this feature being enabled at the instructor account level.
  # This is not the case anymore because we want to keep updating (accepting/
  # rejecting/flagging them, but not create new ones) the grading suggestions
  # and overall comment even if we disable that feature at the program
  # or instructor account level.
  private def ai_grading_enabled?
    activity.supports_ai_grading_feature?
  end

  private def attempt_matches_ai_grading_params?
    return @attempt_matches_ai_params if defined?(@attempt_matches_ai_params)

    @attempt_matches_ai_params = ai_objects_belong_to_current_attempt?
  end

  private def ai_objects_belong_to_current_attempt?
    return true if ai_grading_suggestions_params.blank? && ai_overall_comments_params.blank?

    ai_objects_match_attempt?(AI::GradingSuggestion, ai_grading_suggestions_params.keys) &&
    ai_objects_match_attempt?(AI::OverallComment, ai_overall_comments_params.keys)
  end

  private def ai_objects_match_attempt?(model_class, ids)
    return true if ids.empty?

    # Check if any AI objects exist but don't belong to current attempt
    # Returns true if NO objects exist with different attempt_id
    model_class.where(id: ids).where.not(attempt_id: attempt.id).none?
  end

  def feedback_params
    @feedback_params ||= {
      activity:,
      attempt:,
      current_user: instructor,
      question_label: question.label,
      section:,
      student:,
      cartridge_params: params[:cartridge_params]
    }.tap do |memo|
      # Don't include recording path if there is no new recording (or else
      # we'll have invalid recording rows)
      memo[:recording_path] = recording_path if recording_path.present?

      if include_comment?
        memo[:comment] = comment
        if ai_grading_enabled?
          feedback_item_ai_comments_params[:ai_generated_comment] = ai_generated_comment?
        end
      end

      # Don't include points_earned if it's not present.
      # This ensures that it doesn't disappear when grading a group chat user in practice mode.
      memo[:points_earned] = points_earned if points_earned.present?

      # Don't include the inline corrections unless they have changed
      if corrections_changed?
        memo[:inline_corrections] = corrections
        if ai_grading_enabled?
          feedback_item_ai_comments_params[:ai_generated_inline_corrections] = \
            ai_generated_inline_corrections?
        end
      end

      if corrections_changed? || comment_changed?
        memo[:feedback_notification] = true
        @feedback_notification_sent = true
      end

      if composition_question? && params[feedback_attachment_key].present?
        memo[:attachment_id] = params[feedback_attachment_key]
      end

      memo[:rubric_graded] = rubric_graded?
    end
  end

  private def feedback_item_ai_comments_params
    @feedback_item_ai_comments_params ||= {}
  end

  # This method returns true if instructor's comment should be included in the feedback params
  private def include_comment?
    if activity.group_chat?
      # Don't include if the comment is blank.
      # This ensures that it doesn't disappear when grading a group chat user in practice mode.
      comment.present?
    else
      comment_changed?
    end
  end

  private def update_ai_suggestion_rating_details
    if any_rated_grading_suggestion? || any_rated_overall_comment?
      if ai_suggestion_rating_details[:comment].present?
        comment = ai_suggestion_rating_details[:comment]

        flag_comment = AI::SuggestionRatingDetail.find_or_create_by(
          attempt:,
          question_label: question.label
        ) do |record|
          # Block called when the record does not exist
          record.comment = comment
          record.updated_by = instructor
        end

        if flag_comment.comment != comment
          flag_comment.update!(
            comment:,
            updated_by: instructor
          )
        end
      else
        AI::SuggestionRatingDetail.find_by(
          attempt:,
          question_label: question.label
        )&.destroy
      end
    else
      # If there is no rated records, delete the additional flag comment if it exists.
      AI::SuggestionRatingDetail.find_by(
        attempt:,
        question_label: question.label
      )&.destroy
    end
  end

  private def update_ai_overall_comments
    ai_overall_comment_base_query.where(
      id: ai_overall_comments_params.keys
    ).find_each do |overall_comment|
      attrs = ai_overall_comments_params[overall_comment.id]

      handle_accepted_rejected_edited_attrs(attrs, overall_comment, AI::OverallComment)
      handle_rating_attrs(attrs, overall_comment)

      overall_comment.save!
    end
    # Reset all the overall comments that aren't present in the parameters.
    # If the instructor loads the grading with the AI feature disabled, we'll
    # not receive the grading suggestions in the params, but we still want to
    # reset them back to the "not accepted" and "not rejected" state.
    ai_overall_comment_base_query.where.not(
      id: ai_overall_comments_params.keys
    ).find_each do |overall_comment|
      overall_comment.update!(
        reviewed_status: nil,
        reviewed_by: nil,
        edited: false
      )
    end
  end

  private def update_ai_grading_suggestions
    ai_grading_suggestion_base_query.where(
      id: ai_grading_suggestions_params.keys
    ).find_each do |grading_suggestion|
      attrs = ai_grading_suggestions_params[grading_suggestion.id]

      handle_accepted_rejected_edited_attrs(attrs, grading_suggestion, AI::GradingSuggestion)
      handle_rating_attrs(attrs, grading_suggestion)

      grading_suggestion.save!
    end
    # Reset all the grading suggestions that aren't present in the parameters.
    # If the instructor loads the grading with the AI feature disabled, we'll
    # not receive the grading suggestions in the params, but we still want to
    # reset them back to the "not accepted" and "not rejected" state.
    ai_grading_suggestion_base_query.where.not(
      id: ai_grading_suggestions_params.keys
    ).find_each do |grading_suggestion|
      grading_suggestion.update!(
        reviewed_status: nil,
        reviewed_by: nil,
        edited: false
      )
    end
  end

  private def handle_accepted_rejected_edited_attrs(attrs, entry, model_klass)
    if attrs[:accepted]
      entry.reviewed_status = model_klass::ACCEPTED_STATUS
      entry.reviewed_by = instructor
      entry.edited = !!attrs[:edited]
    elsif attrs[:rejected]
      entry.reviewed_status = model_klass::REJECTED_STATUS
      entry.reviewed_by = instructor
      entry.edited = false
    else
      entry.reviewed_status = nil
      entry.reviewed_by = nil
      entry.edited = false
    end
  end

  private def handle_rating_attrs(attrs, entry)
    entry.rating_category_id = attrs[:rating_category_id]
    entry.rating_comment = attrs[:rating_comment]
    entry.rated_by = if entry.rating_category_id.present? || entry.rating_comment.present?
                       instructor
                     end
  end

  private def any_rated_grading_suggestion?
    ai_grading_suggestion_base_query.where.not(
      rated_by_id: nil
    ).exists?
  end

  private def any_rated_overall_comment?
    ai_overall_comment_base_query.where.not(
      rated_by_id: nil
    ).exists?
  end

  private def check_for_ai_grading_use_inconsistency
    if has_accepted_grading_suggestions_inconsistency? ||
       has_edited_grading_suggestions_inconsistency?
      if Rails.env.live?
        log_ai_grading_suggestions_inconsistency
      else
        Rails.logger.info(
          "#{self.class.name}: Inconsistency between params and corrections: " \
          "#{ai_grading_suggestions_inconsistency_log_attrs}"
        )
        raise 'Inconsistency between params and corrections'
      end
    end
  end

  private def has_accepted_grading_suggestions_inconsistency?
    accepted_from_corrections = accepted_grading_suggestions_ids_from_corrections
    accepted_from_params = accepted_ai_grading_suggestions_ids

    accepted_from_corrections.length != accepted_from_params.length ||
    (accepted_from_corrections & accepted_from_params).length != accepted_from_corrections.length
  end

  private def has_edited_grading_suggestions_inconsistency?
    edited_from_corrections = edited_grading_suggestions_ids_from_corrections
    edited_from_params = edited_ai_grading_suggestions_ids

    edited_from_corrections.length != edited_from_params.length ||
    (edited_from_corrections & edited_from_params).length != edited_from_corrections.length
  end

  private def log_ai_grading_suggestions_inconsistency
    STATS_PROXY.warn(
      ai_grading_suggestions_inconsistency_log_attrs.merge(
        application: :m3,
        attempt_id: attempt.id,
        environment: Rails.env,
        event_action: 'Inconsistency between params and corrections',
        vhl_component: :ai_grading
      )
    )
  end

  private def ai_grading_suggestions_inconsistency_log_attrs
    {
      activity_id: activity.id,
      ai_grading_suggestions_params:,
      accepted_grading_suggestions_ids_from_corrections:,
      accepted_grading_suggestions_ids_from_params: accepted_ai_grading_suggestions_ids,
      edited_grading_suggestions_ids_from_corrections:,
      edited_grading_suggestions_ids_from_params: edited_ai_grading_suggestions_ids,
      inline_correction: corrections,
      question_label: question.label
    }
  end

  private def accepted_grading_suggestions_ids_from_corrections
    @accepted_grading_suggestions_ids_from_corrections ||= ai_grading_suggestions_from_corrections.map(&:id)
  end

  private def edited_grading_suggestions_ids_from_corrections
    if defined? @edited_grading_suggestions_ids_from_corrections
      return @edited_grading_suggestions_ids_from_corrections
    end

    @edited_grading_suggestions_ids_from_corrections ||= ai_grading_suggestions_from_corrections.filter_map do |node|
      grading_suggestion = ai_grading_suggestion_base_query.find_by(
        id: node.id
      )
      if grading_suggestion && grading_suggestion.error_explanation != node.node['data-comment-inline']
        node.id
      end
    end
  end

  AIGradingSuggestionNodeFromCorrections = Struct.new(
    :node,
    :id,
    keyword_init: true
  )

  private def ai_grading_suggestions_from_corrections
    return @ai_grading_suggestions_from_corrections if defined? @ai_grading_suggestions_from_corrections

    doc = Nokogiri::HTML(corrections)
    @ai_grading_suggestions_from_corrections ||= doc.css('span.js-comment-inline').filter_map do |node|
      id = node['data-ai-grading-suggestion-id'].to_i
      AIGradingSuggestionNodeFromCorrections.new(node:, id:) unless id.zero?
    end
  end

  private def accepted_ai_grading_suggestions_ids
    @accepted_ai_grading_suggestions_ids ||= ai_grading_suggestions_params.filter_map do |id, attrs|
      id if attrs[:accepted]
    end
  end

  private def edited_ai_grading_suggestions_ids
    @edited_ai_grading_suggestions_ids ||= ai_grading_suggestions_params.filter_map do |id, attrs|
      id if attrs[:edited]
    end
  end

  private def ai_grading_suggestions_params
    @ai_grading_suggestions_params ||= transform_ai_grading_suggestions_params(
      params[ai_grading_suggestions_key]
    )
  end

  private def transform_ai_grading_suggestions_params(params)
    if params.present?
      params.to_unsafe_hash.to_h do |id, attrs|
        [
          # To make the code easier and writing specs easier,
          # we transform all the ids into numbers.
          Integer(id),
          extract_grading_suggestion_attrs(attrs)
        ]
      end
    else
      {}
    end
  end

  private def extract_grading_suggestion_attrs(attrs)
    {
      accepted: ActiveModel::Type::Boolean.new.cast(attrs[:accepted]),
      edited: ActiveModel::Type::Boolean.new.cast(attrs[:edited]),
      rejected: ActiveModel::Type::Boolean.new.cast(attrs[:rejected]),
      rating_category_id: attrs[:rating_category_id].present? ? Integer(attrs[:rating_category_id]) : nil,
      rating_comment: attrs[:rating_comment]
    }
  end

  private def validate_ai_grading_params
    validate_ai_grading_suggestions
    validate_ai_overall_comments
    validate_ai_rating_categories
  end

  private def validate_ai_grading_suggestions
    return if ai_grading_suggestions_params.blank?

    # Find all the grading suggestions in order to raise a RecordNotFound error
    # if an inexistent id is submitted.
    ai_grading_suggestion_base_query.find(ai_grading_suggestions_params.keys)
  end

  private def validate_ai_overall_comments
    return if ai_overall_comments_params.blank?

    # Find all the overall comments in order to raise a RecordNotFound error
    # if an inexistent id is submitted.
    ai_overall_comment_base_query.find(ai_overall_comments_params.keys)
  end

  private def validate_ai_rating_categories
    # Find all the rating categories
    grading_suggestion_rating_category_ids = ai_grading_suggestions_params.values.filter_map do |attrs|
      attrs[:rating_category_id]
    end
    overall_comment_rating_category_ids = ai_overall_comments_params.values.filter_map do |attrs|
      attrs[:rating_category_id]
    end
    rating_category_ids = grading_suggestion_rating_category_ids + overall_comment_rating_category_ids
    if rating_category_ids.present?
      AI::SuggestionRatingCategory.non_internal.find(rating_category_ids)
    end
  end

  private def ai_overall_comments_params
    @ai_overall_comments_params ||= transform_ai_overall_comments_params(
      params[ai_overall_comments_key]
    )
  end

  private def transform_ai_overall_comments_params(params)
    if params.present?
      params.to_unsafe_hash.to_h do |id, attrs|
        [
          # To make the code easier and writing specs easier,
          # we transform all the ids into numbers.
          Integer(id),
          extract_overall_comment_attrs(attrs)
        ]
      end
    else
      {}
    end
  end

  private def extract_overall_comment_attrs(attrs)
    {
      accepted: ActiveModel::Type::Boolean.new.cast(attrs[:accepted]),
      edited: ActiveModel::Type::Boolean.new.cast(attrs[:edited]),
      rejected: ActiveModel::Type::Boolean.new.cast(attrs[:rejected]),
      rating_category_id: attrs[:rating_category_id].present? ? Integer(attrs[:rating_category_id]) : nil,
      rating_comment: attrs[:rating_comment]
    }
  end

  private def ai_suggestion_rating_details
    @ai_suggestion_rating_details ||= transform_ai_suggestion_rating_details_params(
      params[ai_suggestion_rating_details_key]
    )
  end

  private def transform_ai_suggestion_rating_details_params(params)
    if params.present?
      {
        comment: params['comment']&.strip
      }
    else
      {}
    end
  end

  private def ai_grading_suggestion_base_query
    AI::GradingSuggestion.non_internal.where(
      attempt_id: attempt.id,
      question_label: question.label
    )
  end

  private def ai_overall_comment_base_query
    AI::OverallComment.non_internal.where(
      attempt_id: attempt.id,
      question_label: question.label
    )
  end

  private def composition_question?
    question.class.module_parents.include?(MaestroActivityEngine::ActivityContent::Composition)
  end

  private def points_earned_valid?
    return false unless points_earned.to_s =~ /\A\d*\.?\d*\Z/

    points_earned.to_f >= 0.0 && points_earned.to_f <= question.points_possible.to_f
  end

  def corrections_changed?
    return @corrections_changed if defined? @corrections_changed

    @corrections_changed = if existing_feedback_item
                             if existing_feedback_item.inline_corrections.present?
                               existing_feedback_item.inline_corrections != corrections
                             else
                               has_instructor_markup?(corrections)
                             end
                           else
                             has_instructor_markup?(corrections)
                           end
  end

  def comment_changed?
    return @comment_changed if defined? @comment_changed

    @comment_changed = feedback_changed?(comment_key, :comment)
  end

  def has_instructor_markup?(inline_correction)
    return false if inline_correction.blank?

    INSTRUCTOR_MARKUP_TAGS.any? { |tag| inline_correction.include? tag }
  end

  private def feedback_changed?(key, feedback_attr)
    feedback = existing_feedback_item

    if feedback.blank?
      params[key].present?
    elsif feedback_attr == :points_earned
      number_changed?(params[key], feedback[feedback_attr])
    else
      params[key] != feedback[feedback_attr]
    end
  end

  private def existing_feedback_item
    return @existing_feedback_item if defined? @existing_feedback_item

    @existing_feedback_item = grading_feedback[response_id]
  end

  private def number_changed?(submitted, current)
    # check presence first otherwise setting the score to zero will not work
    # when the feedback record exists but has no score
    (submitted.present? && current.blank?) || submitted.to_f != current.to_f
  end

  private def recording_path
    params[file_path_key]
  end

  private def points_earned
    params[score_key]
  end

  private def comment
    params[comment_key].to_s.strip_tags
  end

  private def criteria_scores_present?(criteria)
    criteria.values.all? do |criterion|
      criterion.values.all? { |score| score != '' }
    end
  end

  private def student_is_practicing?
    params[:practice_mode] && params[:practice_mode][student.id.to_s] == 'true'
  end

  private def rubric_graded?
    params[:rubric_graded] && params[:rubric_graded] == 'true'
  end

  private def rubric_graded_and_submittable?(criteria)
    # Practice mode is coming from group_chat and partner chat when
    # partner_is_practicing? is true
    rubric_graded? && !student_is_practicing? && criteria_scores_present?(criteria)
  end

  private def ai_generated_inline_corrections?
    accepted_ai_grading_suggestions_ids.present?
  end

  private def ai_generated_comment?
    ai_overall_comments_params.values.any? do |attrs|
      attrs[:accepted]
    end
  end

  private def section
    attempt.section
  end

  private def response_id
    @response_id ||= "#{question.label}_student_#{student.id}"
  end

  private def score_key
    "score_for_#{response_id}"
  end

  private def corrections_key
    "inline_corrections_for_#{response_id}"
  end

  private def file_path_key
    "file_path_for_recorded_comment_#{response_id}"
  end

  private def comment_key
    "comment_for_#{response_id}"
  end

  private def ai_grading_suggestions_key
    "ai_grading_suggestions_for_#{response_id}"
  end

  private def ai_overall_comments_key
    "ai_overall_feedback_for_#{response_id}"
  end

  private def ai_suggestion_rating_details_key
    "ai_suggestion_rating_details_for_#{response_id}"
  end

  private def feedback_attachment_key
    "#{response_id}_attachment_id"
  end

  private def corrections
    params[corrections_key]
  end
end

class FeedbackItem < ApplicationRecord
  include EmojiRemovable

  belongs_to :user
  belongs_to :section
  belongs_to :attempt
  belongs_to :recording, optional: true
  belongs_to :composition_attachment,
             foreign_key: :attachment_id,
             inverse_of: :feedback_item,
             optional: true
  has_one :feedback_item_ai_comment, required: false, dependent: :destroy
  accepts_nested_attributes_for :feedback_item_ai_comment, allow_destroy: true

  scope :by_attempts, ->(attempt_ids) { where(attempt_id: attempt_ids) }
  scope :by_questions, ->(question_labels) { where(question_label: question_labels) }
  scope :by_students, ->(user_ids) { where(user_id: user_ids) }
  scope :by_sections, ->(section_ids) { where(section_id: section_ids) }

  after_save :set_feedback_attachment

  delegate(
    :ai_generated_comment?,
    :ai_generated_inline_corrections?,
    to: :feedback_item_ai_comment,
    allow_nil: true
  )

  def self.remove_attachment(attachment_id)
    feedback_item = FeedbackItem.find_by(attachment_id: attachment_id)
    feedback_item&.update!(composition_attachment: nil)
  end

  def self.submit(params)
    attempt = params[:attempt] ||
              Attempt.find_by_student_section_and_activity(params[:student],
                                                           params[:section],
                                                           params[:activity])

    return unless attempt
    feedback_item = attempt.feedback_item(params[:question_label]) ||
                    new(params.slice(:question_label, :section)
                              .merge(attempt: attempt, user: params[:student]))

    feedback_item.update_recording(params[:current_user], params[:recording_path])

    feedback_item_ai_comment_attributes = (params[:feedback_item_ai_comments] || {}).slice(
      :ai_generated_comment,
      :ai_generated_inline_corrections
    )
    feedback_item.update!(
      params.slice(
        :attachment_id,
        :comment,
        :inline_corrections,
        :points_earned
      ).merge(
        feedback_item_ai_comment_attributes:
      )
    )

    unless skip_feedback_notification?(attempt, params)
      feedback_item.update_feedback_notification_for_student
    end
    attempt.process_instructor_grading(
      cartridge_params: params[:cartridge_params],
      rubric_graded: params[:rubric_graded]
    )
  end

  def update_feedback_notification_for_student
    ai_used = ai_generated_comment? || ai_generated_inline_corrections?
    # We only want one no dismissed feedback notification per activity.
    # This is take care by the ActivityFeedbackNotification class that will
    # automatically destroy all the undismissed feedback notification for that
    # activity.
    # But, we do not want to set the AI flag to false if it was previously true.
    # That's why we use the find_or_create_by method to find the last no dismissed
    # notification and update the AI flag if needed.
    notification = ActivityFeedbackNotification.find_or_create_by(
      section:,
      user:,
      activity: attempt.activity,
      dismissed: false
    ) do |record|
      record.ai_used = ai_used
    end

    if ai_used && !notification.ai_used?
      notification.update!(ai_used: true)
    end
  end

  def self.skip_feedback_notification?(attempt, params)
    ((attempt.assignment && attempt.assignment.grade_availability == :never) || params[:feedback_notification].blank?)
  end
  private_class_method :skip_feedback_notification?

  def update_recording(user, recording_path)
    if recording.blank? || recording_different?(recording_path)
      self.recording = new_recording(user, recording_path)
    end
  end

  def recording_different?(new_recording_path)
    new_recording_path.present? && (new_recording_path != recording.recording_path)
  end
  private :recording_different?

  def self.find_number_of_questions_graded_for_students(student_ids, attempt_ids, questions)
    scope = where( :attempt_id => attempt_ids, :user_id => student_ids, :question_label => questions.map(&:label) )
    scope = scope.where( 'points_earned is not null' )

    ret_hash = {}
    student_ids.each { |id| ret_hash[id.to_s] = 0 }

    scope.each do |rec|
      ret_hash[rec.user_id.to_s] += 1
    end
    ret_hash
  end

  def self.find_number_of_students_graded_for_questions(questions, attempt_ids)
    number_of_students_graded_for_each_question = questions.inject(Hash.new(0)){ |memo, question| memo[question.label] = 0; memo }

    feedback_items = where(attempt_id: attempt_ids).where('points_earned is not null')

    feedback_items.each { |feedback| number_of_students_graded_for_each_question[feedback.question_label] += 1 }

    number_of_students_graded_for_each_question
  end

  def self.by_question_user_and_attempt(question, user, attempt)
    by_questions(question.label).by_students(user).by_attempts(attempt)
  end

  def self.find_student_points_earned_for_question(question, student_id, attempt)
    by_question_user_and_attempt(question, student_id, attempt).first(:select => 'points_earned')
  end

  def self.find_comment_for_question(question, student_id, attempt)
    by_question_user_and_attempt(question, student_id, attempt).first(:select => 'comment')
  end

  def self.find_inline_corrections_for_question(question, student_id, attempt)
    by_question_user_and_attempt(question, student_id, attempt).first(:select => 'inline_corrections')
  end

  def self.find_corrections_and_comment_and_points_earned_and_recording_for_question(question, student_id, attempt)
    by_question_user_and_attempt(question, student_id, attempt).first(:select => 'inline_corrections, comment, points_earned, recording_id')
  end

  def self.find_feedback_for_question(question_label, user, attempt)
    where(question_label: question_label, user_id: user, attempt_id: attempt)
  end

  def new_recording(user, recording_path)
    return nil if recording_path.blank?
    recording = Recording.new(:user => user, :recording_path => recording_path)
    recording.save
    recording
  end

  def attributes_to_clean
    [:inline_corrections, :comment]
  end

  def set_feedback_attachment
    CompositionAttachment.remove_draft_flags_from attachment_id
  end
  private :set_feedback_attachment
end

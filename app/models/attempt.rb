class Attempt < ApplicationRecord
  include AttemptSubmission
  include PendingTrueFalseEnhancedCheckable

  MAX_POSSIBLE_TIME_DELTA = 1.hour.to_i

  attr_accessor :disable_enhanced_feedback, :assignment

  belongs_to :user
  # optional: true to allow section_id 0 for unenrolled students/instructors.
  belongs_to :section, optional: true
  # unscope is used here to get a question bank instance of activity
  # which is excluded via a default_scope on the Activity class
  belongs_to :activity, -> { unscope(where: :question_bank_revision_id) }
  belongs_to :scoring_ruleset

  after_initialize :enable_stats

  has_many :feedback_items
  has_one :rubric_criteria_score, required: false
  has_one :attempt_config, dependent: :destroy

  has_many(
    :ai_grading_suggestions,
    class_name: 'AI::GradingSuggestion',
    dependent: :destroy
  )

  has_many(
    :ai_grading_suggestion_jobs,
    class_name: 'AI::GradingSuggestionJob',
    dependent: :destroy
  )

  has_many(
    :ai_overall_comments,
    class_name: 'AI::OverallComment',
    dependent: :destroy
  )

  has_one(
    :ai_virtual_chat_session,
    class_name: 'AI::ConversationSession',
    dependent: :destroy
  )

  act_as_attempt_submission

  validates_presence_of :activity_id, :user_id
  validates_numericality_of :time_spent, :greater_than => -1, :allow_nil => false

  scope :submitted_attempts, lambda { |section, activities|
    where(section_id: section,
          activity_id: activities,
          user_id: section.current_students_base,
          status_code: [AttemptStatus::CODE_SUBMITTED, AttemptStatus::CODE_COMPLETED])
  }

  scope :by_section, ->(*section) { where(section_id: section) }
  scope :by_activities, ->(*activities) { where(activity_id: activities) }
  scope :by_student, ->(*students) { where(user_id: students) }
  scope :by_cms_activity, ->(cms_activity_id) { where(cms_activity_id: cms_activity_id) }
  scope :active, lambda {
    where(['attempts.status_code is null OR attempts.status_code <> ?', AttemptStatus::CODE_RESET])
  }
  scope :was_reset, -> { where(status_code: AttemptStatus::CODE_RESET) }
  scope :submitted_or_completed, lambda {
    where(status_code: [AttemptStatus::CODE_SUBMITTED, AttemptStatus::CODE_COMPLETED])
  }
  scope :without_time_spent, -> { where(time_spent: 0) }

  delegate :attachment_for, :to => :results, :allow_nil => true
  delegate :partner_chat?, :virtual_chat?, :solo_video_recording?, :solo_video_recording_or_included_in_multipart_activity?, :group_chat?, :to => :activity, :allow_nil => true
  delegate :status, :attempted?, :complete?, :completed?, :submitted?, :unsubmitted?, :reset?, :expanded_status, :submitted_or_completed?, :to => :attempt_status
  delegate :artifact_sharing_status, to: :attempt_config, allow_nil: true

  def initialize(attrs = {})
    super(attrs)
    @practice = attrs && attrs[:practice].presence || false
    @practice_complete = false
  end

  def enable_stats
    extend(AttemptStats)
  end

  # takes a single student, a single section, and a list of activities
  def self.by_student_section_and_activity(student, section, *activities)
    by_student(student).by_section(section).by_activities(*activities)
  end

  # takes an array of students, an array of sections, and a single activity
  # passing in a single student or section that isn't in an array will break the scope
  def self.completed_or_submitted_by_students_sections_and_activity(students, sections, activity)
    by_student(*students).by_section(*sections).by_activities(activity).submitted_or_completed
  end

  # takes an array of sections. passing in a single section that isn't in an array will break the scope
  def self.activity_xml_file_paths(sections)
    by_section(*sections).collect{ |attempt| Activity.filepath_from_revision_id(attempt.cms_revision_id, attempt.activity.instructor_created?) }.uniq
  end

  def escape_artifact_export?
    artifact_sharing_status == 'in_progress' || artifact_sharing_status == 'success'
  end

  def find_or_create_ai_virtual_chat_session
    if practice?
      AI::ConversationSession.create!(activity_id:, user_id:)
    else
      return unless persisted?

      ai_virtual_chat_session || create_ai_virtual_chat_session(activity_id:, user_id:)
    end.tap(&:create_initial_message)
  end

  def opened?
    status_code == AttemptStatus::CODE_OPENED
  end

  def started?
    status_code == AttemptStatus::CODE_STARTED
  end

  def assignment_time_limit
    @time_limit ||= (assignment.try(:time_limit_for_student, user) || 0) * 60
  end

  def assignment_time_limit_exists?
    assignment_time_limit == 0
  end

  def time_left_in_seconds
    return 0 if assignment_time_limit_exists?
    time_elapsed = start_time.present? ? (Time.now.utc.to_i - start_time.to_i) : 0
    [0, (assignment_time_limit - time_elapsed)].max
  end

  def assignment_max_attempts
    assignment ? assignment.max_attempts : activity_max_attempts
  end

  def assignment #TT
    if section_id
      @assignment ||= Assignment.where(
        section_id: section_id,
        assignable_id: activity_id,
        assignable_type: 'Activity'
      ).first
    end
  end

  def activity_max_attempts
    activity.max_attempts ? activity.max_attempts : -1
  end

  def hash_key
    "#{section_id}_#{activity_id}_#{activity.class}"
  end

  def mark_as_started!
    if (status_code == AttemptStatus::CODE_OPENED || status_code == AttemptStatus::CODE_UNOPENED)
      self.start_time = Time.now.utc
      self.status_code = AttemptStatus::CODE_STARTED
      save!
    end
  end

  def last_possible?
    attempt_track.final?
  end

  def practice=(practice)
    @practice = practice
  end

  def has_submittable_activity?
    activity.gradable?
  end

  def practice?
    @practice
  end

  def practice_complete=(complete)
    @practice_complete = complete
  end

  def practice_complete?
    @practice_complete
  end

  def student
    user
  end

  def attempt_status
    @attempt_status ||= AttemptStatus.new(self)
  end

  def help_requestable?
    !completed? || !activity.submittable?
  end

  def review_requestable?
    completed? && activity.submittable?
  end

  def attempt_config_attributes=(attributes)
    attempt_config || build_attempt_config
    attempt_config.update(attributes)
  end

  def current_view
    if activity.santillana?
      :show
    elsif !activity.submittable?
      :show
    elsif attempted? || saved_values?
      if complete?
        :complete
      elsif saved_values?
        :submit
      else
        :decide
      end
    else
      :show
    end
  end

  def max_attempt_policy
    @max_attempt_policy ||= MaxAttemptPolicy.new(activity, assignment)
  end
  private :max_attempt_policy

  def attempt_track
    if activity_id.nil? || max_attempt_policy.unsubmittable? #activity content type is read/only, cannot be submitted
      @attempt_track ||= AttemptTrack.new(0, 0)
    else
      @attempt_track ||= AttemptTrack.new(attempt_number, max_attempt_policy.max_attempts)
      # keep attempt_number current in cached object
      @attempt_track.attempt_number = attempt_number
      @attempt_track.complete = complete?
      @attempt_track.practice = practice?
    end

    @attempt_track
  end

  private def scoring_ruleset_with_activity_language
    scoring_ruleset.tap do |memo|
      memo.chinese = true if activity.content_object.language == 'zh'
    end
  end

  def validate_responses(activity, submitted_values, request_env, mode = :submitted)
    raise "Can't validate responses for santillana activities" if activity.santillana?

    # This method is used to generate a results object, sometimes for
    # writing results, sometimes for checking answers once
    raise "no scoring ruleset set for attempt" unless scoring_ruleset

    student_submission = check_fields(submitted_values)

    revision_activity.content_object.validate_responses(
      student_submission,
      scoring_ruleset_with_activity_language,
      mode,
      disable_enhanced_feedback,
      feedback_items
    )
  end

  private def check_fields(submitted_values)
    if revision_activity.allow_missing_answers?
       # For activities that render a subset of the total questions,
       # do not fill in missing fields
       submitted_values
    else
      # Ensure that all questions are passed to validate responses,
      # even blank answers.
      # Todo what do we do when it is a smartbook? Is this relevant?
      # When is it called?
      revision_activity.result_labels.each_with_object(
        HashWithIndifferentAccess.new
      ) do |label, memo|
        memo[label] = ''
      end.merge(submitted_values)
    end
  end

  def points_earned_for_feedback_item(question_label)
    fb_item = feedback_item(question_label)
    fb_item.points_earned if fb_item
  end

  def feedback_item(question_label)
    @feedback_items ||= feedback_items
    @feedback_items.detect{|feedback| feedback.question_label == question_label}
  end

  def common_instructor_feedback
    feedback_item(nil)
  end

  # Candidate for extracting to concern. Only consumer of these methods:
  #  all_questions_have_scores?
  #  current_total_points
  #  points_earned_for_feedback_item
  #  results_points_earned
  #  update_grading_notification_for_activity
  def process_instructor_grading(cartridge_params:, rubric_graded: false)
    # Ensure we include the answer that was just submitted for this attempt
    feedback_items.reload

    # covers the case where feedback_items may changed
    # so we need to invalidate the cached results
    # because they depend on feedback_items and might be out of date.
    remove_instance_variable(:@results) if defined?(@results)

    # Don't update the score for non-smartbook activity until we have a "final" score.
    return unless activity.smart_book? || all_questions_have_scores?

    score_action = GradebookEngine::GradebookAPI.find_score(
      activity_id: activity_id,
      section_id: section_id,
      user_id: user_id
    )
    return if score_action.blank?

    # update rubric_graded flag for summation
    score_action.summation = score_action.summation.merge(rubric_graded: rubric_graded)

    # reset partial pending flag if all questions have scores
    ::Gradebook::InstructorGrading.new(
      score_action,
      current_total_points,
      reset_partial_pending: activity.smart_book? && all_questions_have_scores?
    ).process
    # Send grade passback for cartridge students
    if user.cartridge? && all_questions_have_scores?
      Cartridge::GradePassback.new(user, self, cartridge_params).process
    end

    # update student standards results
    store_standards_results(results) if can_store_standards_results?

    if assignment && assignment.grade_availability != :never
      update_grading_notification_for_activity(section, user, activity)
    end
  end

  def add_time_spent(start_time, end_time)
    time_spent_delta = TimeSpentDeltaCalculator.new(start_time, end_time).time_spent_delta
    update(:time_spent => time_spent + time_spent_delta)
  end

  def effective_scoring_ruleset
    activity.content_object.effective_ruleset(scoring_ruleset)
  end

  def results
    @results ||= find_results
  end

  def find_results
    results = nil

    if submitted_values?
      convert_response_to_partner_chat_recording
      convert_response_to_solo_video_recording
      convert_response_to_group_chat_recording

      # Reading responses
      results = revision_activity.content_object.validate_responses(
        revision_activity.smart_book? ? smartbook_responses.answered : stored_responses,
        scoring_ruleset_with_activity_language,
        :submitted,
        disable_enhanced_feedback,
        feedback_items
      )
    end

    if saved_values?
      results ||= MaestroActivityEngine::ActivityContent::Results.new
      results.update_to_saved(saved_responses)
      results.disable_enhanced_feedback = disable_enhanced_feedback
    end

    results
  end

  # We need to memoize this object to avoid multiple hits to MAE.
  # The grading sets code sends the question label, but it needs
  # to use the whole results object.
  # TODO: Refactor grading sets code to avoid the unused argument.
  def results_for_question(_question_label)
    @results_for_question ||= results
  end

  def revision_activity
    # this ensures the the correct revision of the activity's content object is generated
    @revision_activity ||= activity.tap { activity.ensure_correct_version(cms_revision_id) }
  end

  def teammates_from_results
    if partner_chat? || group_chat?
      response = results.first[:response]
      teammate_ids = if partner_chat?
                       response.user_id == user.id ? response.partner_id : response.user_id
                     else
                       all_participant_ids = response.participants.map(&:to_i) + [response.user_id]
                       all_participant_ids.reject!{ |user_id| user_id == user.id}
                     end
      User.where(id: teammate_ids)
    end
  end

  def convert_response_to_partner_chat_recording
    if partner_chat?
      revision_activity.content_object.finder_class = PartnerChatRecording
    end
  end

  def convert_response_to_solo_video_recording
    if solo_video_recording_or_included_in_multipart_activity?
      if solo_video_recording?
        revision_activity.content_object.finder_class = SoloVideoRecording
      else
        revision_activity.content_object.solo_video_recording_subactivity.finder_class =  SoloVideoRecording
      end
    end
  end

  def convert_response_to_group_chat_recording
    if group_chat?
      revision_activity.content_object.finder_class = GroupChatRecording
    end
  end

  def submission_length(other_results = nil)
    activity_results = other_results || results
    raise "nil activity_results for attempt: #{id}" if activity_results.nil?

    return nil unless activity_results.instructor_graded_score_pending?

    # this ignores question type and is the desirable behavior at this time
    total_chars = 0
    activity_results.each do |result|
      next if response_has_no_length?(result)

      total_chars += result[:response].to_s.strip.html_decode.strip_tags.remove_accents.length
    end
    total_chars
  end

  def self.create_completed(user, activity, section)
    attempt = Attempt.find_or_new(user, activity, section)
    attempt.update!(
      attempt_number: (attempt.attempt_number.zero? ? 1 : attempt.attempt_number),
      status_code: AttemptStatus::CODE_COMPLETED
    )
    unless activity.gradable?
      submission = Gradebook::Submission.new(user, section, activity)
      submission.submit_nongradable
    end
    attempt
  end

  # takes a single student, single section, and single activity
  # don't pass in any arrays to this method.
  def self.active_attempt(user, section, activity)
    attempt = Attempt.by_student_section_and_activity(user, section, activity).active.first

    if attempt && !attempt.attempted? && !attempt.saved_values?
      attempt.update(:cms_revision_id => activity.revision_id)
    end
    attempt
  end

  def self.find_or_create_with_scoring_ruleset(user, activity, section_id, scoring_ruleset = nil)
    # user and activity must be specified as object instances, section as an id, with zero a valid value

    # Using a default of nil in the method definition instead ScoringRuleset.default lets us pass nil in from the
    # calling method, and still get the default value we want. The alternative is pre-checking the value in the calling
    # method, then using different method calls for when we have a ruleset and when we don't.
    scoring_ruleset ||= ScoringRuleset.default

    attempt = active_attempt(user, section_id, activity)
    attempt ||= safely_create_unique(user, section_id, activity, scoring_ruleset)

    if attempt.scoring_ruleset_id.blank? || attempt.unsubmitted?
      attempt.update!(:scoring_ruleset => scoring_ruleset)
    end
    attempt
  end

  def self.safely_create_unique(user, section_id, activity, scoring_ruleset)
    # user and activity must be specified as object instances,
    # section as an id, with zero a valid value

    begin
      create!(user: user,
              activity: activity,
              section_id: section_id,
              status_code: AttemptStatus::CODE_OPENED,
              cms_activity_id: activity.cms_activity_id,
              cms_revision_id: activity.revision_id,
              scoring_ruleset: scoring_ruleset)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid => e
      raise e unless e.message =~ /Mysql2::Error: Duplicate entry/
      where(user_id: user.id,
            activity_id: activity.id,
            section_id: section_id,
            status_code: AttemptStatus::CODE_OPENED).first
    end
  end
  private_class_method :safely_create_unique

  def self.find_or_new(user, activity, section)
    activity_id = activity.class == Activity ? activity.id : activity
    section_id = (section && section.instance_of?(Section)) ? section.id : section.to_i
    attempt = active_attempt(user, section, activity)

    if attempt.blank?
      attempt = Attempt.new(:user => user,
                            :cms_activity_id => activity.cms_activity_id,
                            :cms_revision_id => activity.revision_id,
                            :activity_id => activity_id,
                            :section_id => section_id,
                            :status_code => AttemptStatus::CODE_OPENED,
                            :scoring_ruleset => ScoringRuleset.default)
    end
    attempt
  end

  def self.practice_attempt(user, section_id, activity)
    attempt = Attempt.find_or_new(user, activity, section_id)
    if attempt.complete?
      activity = activity.class == Activity ? activity : Activity.find_by_id(activity.id)
      scoring_ruleset = attempt.scoring_ruleset
      # Note that we aren't saving an attempt here, just return a pratice object to work with.
      attempt = Attempt.new(:user_id => user.id,
                            :cms_activity_id => activity.cms_activity_id,
                            :cms_revision_id => activity.revision_id,
                            :activity_id => activity.id,
                            :section_id => section_id,
                            :practice => true)
      attempt.scoring_ruleset = scoring_ruleset
    else
      attempt = nil
    end
    attempt
  end

  def self.find_by_student_section_and_activity(user, section, activity)
    attempts = activity_attempts(section, user, activity)
    return nil if attempts.empty?
    attempts.first
  end

  def self.activity_attempts(sections, users, activities)
    Attempt.by_student(*users).by_section(*sections).by_activities(*activities).active
  end

  def self.find_submitted_attempts_for_activity_and_students(sections, users, activity, cache_results = false)
    ret_hash = {}
    attempts = Attempt.includes(:activity, :scoring_ruleset, :feedback_items).where(
      section_id: sections.map(&:id),
      user_id: users.map(&:id),
      activity_id: activity,
      status_code: [AttemptStatus::CODE_SUBMITTED, AttemptStatus::CODE_COMPLETED]
    )
    if cache_results
      results_cacher = ResultsApiDatastore::MultipleAttempts.new(attempts)
      if results_cacher.cacheable?
        attempts.each do |attempt|
          attempt.stored_responses = if attempt.activity.smart_book?
                                       attempt.smartbook_responses.answered
                                     else
                                       results_cacher.stored_response(attempt)
                                     end
        end
      end
    end

    attempts.each do |attempt|
      ret_hash[attempt.user_id.to_s] = attempt
    end
    ret_hash
  end

  def instructor_graded_questions
    if activity.smart_book?
      smartbook_responses.instructor_graded
    elsif activity.true_false_enhanced?
      revision_activity.questions.select do |question|
        pending_true_false_enhanced?(question)
      end
    else
      revision_activity.instructor_graded_questions
    end
  end

  def <=>(other_attempt)
   return 1 unless other_attempt
   raise "uncomparable attempt records" unless user_id == other_attempt.user_id
   raise "uncomparable attempt records" unless cms_activity_id == other_attempt.cms_activity_id
   raise "uncomparable attempt records" unless section_id == other_attempt.section_id

   if completed? && other_attempt.completed?
     return ((updated_at > other_attempt.updated_at) ? 1 : -1)
   end
   return 1 if completed?
   return -1 if other_attempt.completed?
   if submitted? && other_attempt.submitted?
     return ((updated_at > other_attempt.updated_at) ? 1 : -1)
   end
   return 1 if submitted?
   return -1 if other_attempt.submitted?

   return ((updated_at > other_attempt.updated_at) ? 1 : -1)
  end

  def newer_submission(other_attempt)
   return self unless other_attempt
   raise "uncomparable attempt records" unless user_id == other_attempt.user_id
   raise "uncomparable attempt records" unless cms_activity_id == other_attempt.cms_activity_id
   raise "uncomparable attempt records" unless section_id == other_attempt.section_id

   return self if completed?
   return other_attempt if other_attempt.completed?
   return self if submitted?
   return other_attempt if other_attempt.submitted?

   raise "neither of the records are submitted or completed"
  end

  def set_attempt(complete_status, save_mode, start_time, end_time)
    time_spent_delta = TimeSpentDeltaCalculator.new(start_time, end_time).time_spent_delta

    if save_mode == Mode::SAVED
      set_status = if status == :unopened
                     0
                   else
                     status_code
                   end

      update!(
        status_code: set_status,
        time_spent: time_spent + time_spent_delta
      )
    else
      set_status = complete_status ? AttemptStatus::CODE_COMPLETED : AttemptStatus::CODE_SUBMITTED
      update!(
        attempt_number: (attempt_number + 1),
        status_code: set_status,
        time_spent: time_spent + time_spent_delta
      )
    end
  end
  private :set_attempt

  def reset_attempt
    if saved_values?
      update!(attempt_number: 0, status_code: AttemptStatus::CODE_OPENED)
      reset_submission
    else
      # we can only have a max of one attempt per section and activity that has been reset, so before marking
      # this one as reset, we have to get rid of any existing ones
      Attempt.was_reset.by_student_section_and_activity(
        user, section, activity
      ).each(&:destroy)
      update!(:status_code => AttemptStatus::CODE_RESET)
    end
    reset_smartbook_state if activity.smart_book?
    reset_ai_virtual_chat_session if activity.ai_virtual_chat?
  end

  def self.reset_attempt(user, section, activity)
    attempt = Attempt.active_attempt(user, section, activity)
    if attempt
      attempt.reset_attempt
      attempt.rubric_criteria_score&.destroy
      # We change the review_request to help_request in order for the
      # instructor to still be able to see them and respond to them after a
      # work reset has taken place.
      user.help_requests.by_section_activity_and_request_type(
        section, activity, 'request_review'
      ).update_all(request_type: 'request_help')
      activity_notifications = activity.notifications_by_user_and_section(user, section)
      activity_notifications.delete_all if activity_notifications
      attempt.feedback_items.destroy_all
      attempt.remove_standards_results if activity.standards_test?
    else
      raise "Attempt not found for User #{user.id} : Section #{section.id} : Activity #{activity.id}"
    end
  end

  def self.completed_activity_ids(user, section, activities)
    return Array.new if section.nil? || section.id.to_s == '0'
    completed_ids = Array.new

    #TODO: Change this to use a scope so we only grab completed attempts
    find_attempts_for_activities(user, section, activities).each {|attempt| completed_ids << attempt.activity_id if attempt.complete?}
    completed_ids
  end

  def self.all_submitted_and_completed_activities(user, section_id)
    return Array.new if section_id.to_s == '0'
    attempts = where(
      section_id: section_id,
      user_id: user.id,
      status_code: [AttemptStatus::CODE_SUBMITTED, AttemptStatus::CODE_COMPLETED]
    )
    attempts.collect{|attempt|attempt.activity}
  end

  def self.status_for_activities(user, section, activities)
    # If we've got a nil section, an empty array, or an array of nils, use section zero.
    section = 0 if (section.instance_of?(Array) && section.compact.empty?) || section.nil?
    activity_status_hash = {}

    # Seed the hash with the :unopened status.
    activities.each {|activity| activity_status_hash[activity.id] = :unopened }

    # should we exclude attempts that have been reset here?
    # if not, there's a chance we could be over-writing values in the hash when there are 2 attempts
    # for an activity, one active and one that has been reset
    find_attempts_for_activities(user, section, activities).each {|attempt| activity_status_hash[attempt.activity_id] = attempt.expanded_status }

    activity_status_hash
  end

  def self.attempts_for_activities(user, section, activities) #TT
    return Hash.new if section.to_s == '0' || section.nil?
    find_attempts_for_activities(user, section, activities).inject({}) {|memo, attempt| memo[attempt.activity_id] = attempt; attempt.section = section; memo }
  end

  def mark_as_completed(start_time, end_time)
    time_spent_delta = TimeSpentDeltaCalculator.new(start_time, end_time).time_spent_delta
    update(status_code: AttemptStatus::CODE_COMPLETED,
                       time_spent: time_spent + time_spent_delta)
  end

  def stored_responses=(resp)
    @stored_responses = resp
  end

  def stored_responses
    @stored_responses ||= results_datastore.stored_responses
  end

  def smartbook_responses
    return @smartbook_responses if @smartbook_responses
    # get all answered subactivities from the Smartbook
    if stored_responses.present?
      @smartbook_responses = Smartbook::Responses.new(
        stored_responses['statements'].map { |attrs| Xapi::Statement.new(attrs) }
      )
    end
  end

  def smartbook_responses_with_feedback
    return @smartbook_responses_with_feedback if @smartbook_responses_with_feedback
    return [] unless smartbook_responses.present?
    feedback_items_by_label = feedback_items.index_by(&:question_label)
    @smartbook_responses_with_feedback = smartbook_responses.answered.each_with_object([]) do |response, memo|
      feedback_item = feedback_items_by_label[response.label]
      memo << [response, feedback_item] if feedback_item
    end
  end

  # covers the case where a new answered statement was just stored
  # and we need to re-retrieve all the responses;
  # due to memoization stored_responses and smartbook_responses
  # might have prior values.
  def uncache_smartbook_responses
    if defined?(@smartbook_responses)
      remove_instance_variable(:@smartbook_responses)
    end
    if defined?(@smartbook_responses_with_feedback)
      remove_instance_variable(:@smartbook_responses_with_feedback)
    end
  end

  # does not apply to smartbooks
  def saved_responses
    results_datastore.saved_responses
  end

  def write_results(results, complete_status, save_mode = Mode::SUBMITTED, start_time = Time.now.to_i, end_time = Time.now.to_i)
    raise "Submitted params are not complete." unless valid_submission?(results)

    # ensure we have a saved attempt record before writing the submission
    set_attempt(complete_status, save_mode, start_time, end_time)
    results_datastore.write(results, save_mode)
    CompositionAttachment.remove_draft_flags_from( results.attachment_ids )
    store_standards_results(results) if activity.auto_graded? && can_store_standards_results?
  end

  private def can_store_standards_results?
    activity.standards_test? && activity.cms_activity_id
  end

  def store_standards_results(results)
    StandardsResults.create_or_update(
      user_id: user_id,
      section_id: section_id,
      cms_activity_id: cms_activity_id,
      results_data: results.standards_results
    )
  end

  def <(another_attempt)
    updated_at < another_attempt.updated_at
  end

  def results_datastore
    ensure_api_results
    @results_datastore ||= DataStorable.build(self)
  end

  # Composition attachments and PartnerChatRecordings have no measurable
  # length. If response is an array, it's a MultipleAnswer response, which
  # also has no meaningful length.
  private def response_has_no_length?(result)
    result[:is_attachment] ||
    result[:response].is_a?(PartnerChatRecording) ||
    result[:response].is_a?(GroupChatRecording) ||
    result[:response].is_a?(Array) ||
      result[:response].is_a?(SoloVideoRecording)
  end

  def ensure_api_results
    if submission_migration_needed?
      SubmissionMigrator.sync_api(self)
    end
  end
  private :ensure_api_results

  def submission_migration_needed?
    (submission_id.nil? && submitted_values?) || (saved_submission_id.nil? && saved_values?)
  end
  private :submission_migration_needed?

  def current_total_points
    if activity.smart_book?
      Smartbook::ScoreCalculator.new(self).points_earned
    else
      revision_activity.questions.sum do |question|
        if revision_activity.table_activity? && question.type == 'inline_open_ended'
          question.wols.sum do |wol|
            points_earned_for(wol.label)
          end
        else
          points_earned_for(question.label)
        end
      end.to_f
    end
  end

  private def points_earned_for(label)
    points_earned_for_feedback_item(label) || results_points_earned(label)
  end

  def results_points_earned(question_label)
    if activity.smart_book?
      results_obj = smartbook_responses
    else
      results_obj = results_for_question(question_label)
    end
    results_obj ? results_obj.points_earned(question_label) : 0
  end

  # Select all feedback items with a score but that is not included in `questions`.
  # This happens when the student did not submit an interaction but the instructor
  # graded it.
  private def unsubmitted_question_scores
    @unsubmitted_question_scores ||= begin
      answered_questions_by_label = smartbook_responses.answered.index_by(&:label)
      feedback_items.select do |feedback|
        feedback.question_label.present? &&
        feedback.points_earned.present? &&
        !answered_questions_by_label.key?(feedback.question_label)
      end
    end
  end

  def remove_standards_results
    StandardsResults.where(
      user_id: user_id,
      cms_activity_id: activity.cms_activity_id,
      section_id: section_id
    ).delete_all
  end

  private def reset_smartbook_state
    Xapi::StateDeleter.new(self).delete
    Xapi::Statement.delete_statements_by_attempt(self)
  end

  private def reset_ai_virtual_chat_session
    ai_virtual_chat_session&.restart
  end

  def self.newest_submitted_attempts(section,activities)
    Attempt.submitted_attempts(section,activities).inject({}){ |attempt_map, attempt|
          hash_key = "#{attempt.activity_id}_#{attempt.user_id}"
          attempt_map[hash_key] ||= attempt.newer_submission(attempt_map[hash_key])
          attempt_map
    }.values
  end

  def self.transfer_work(student, section_from, section_to)
    where(section_id: section_from.id, user_id: student.id).update_all(section_id: section_to.id)
  end

  def propagate_time_spent_to_score
    # Once attempted, time_spent will be updated here
    # Don't update if not attempted or in section 0
    if attempted? && section && section.non_zero?
      GradebookEngine::GradebookAPI.update_time_spent(
        user_id, section_id, activity_id, section.school_id,
        time_spent: time_spent
      )
    end

    # Non_gradable, non-completable activities with a non-submitted attempt
    # are submitted here, setting time_spent. Subsequent calls will update
    # time_spent in the previous clause.
    if !attempted? && activity.not_gradable_or_completable?
      ::Gradebook::Submission.new(user, section, activity)
                             .submit_nongradable(time_spent)
    end
  end

  def all_questions_have_scores?
    # get a list of feedback_items for questions that have been graded
    graded_feedback = feedback_items.select do |feedback|
      feedback.question_label.present? && feedback.points_earned.present?
    end
    question_list = instructor_graded_questions.map(&:label)
    (question_list - graded_feedback.map(&:question_label)).empty?
  end

  private

  def update_grading_notification_for_activity(section, user, activity)
    activity_graded_notification = ActivityGradedNotification.new(:section => section, :user => user, :activity => activity)
    activity_graded_notification.save!
  end

  def valid_submission?(results)
    # We need to verify that results contains all question labels for the activity.
    (revision_activity.result_labels - results.keys).empty?
  end
  private :valid_submission?

  def self.find_submitted_attempts_for_activities(student_list, section_ids, activities, opts = {} )
    opts.merge!(:status_code => [AttemptStatus::CODE_SUBMITTED, AttemptStatus::CODE_COMPLETED])
    Attempt.find_attempts_for_activities(student_list, section_ids, activities, opts)
  end

  def self.find_attempts_for_activities(user, section, activities, opts = {})
    section = section.to_a if section.respond_to?(:to_a)
    conditions = { user_id: user, section_id: section, activity_id: activities }
    where(conditions.merge(opts))
  end

  class TimeSpentDeltaCalculator

    def initialize(start_time, end_time)
      @start_time = start_time
      @end_time = end_time
      @delta = end_time.to_i - start_time.to_i
    end

    def time_spent_delta
      if @start_time && @end_time && @delta > 0
        [@delta, Attempt::MAX_POSSIBLE_TIME_DELTA].min
      else
        0
      end
    end

  end

end

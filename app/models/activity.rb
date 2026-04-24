require 'fileutils'

class Activity < ApplicationRecord
  include Attemptable
  include InstructorGradableQuestionCheckable
  include ScorableSorter
  include Etl

  ACTIVITY_TYPES = %w[
    ai_virtual_chat
    composition
    diagnostic_v2
    exam
    external_link
    group_chat
    multi_type_current_event
    open_ended
    recording_v2
    smart_book
    solo_video_recording
    speech_rec_listen_repeat
    static_book
    study_plan_practice_test
    true_false_enhanced
    upload_file_activity
    video_virtual_chat
    virtual_chat
  ].freeze
  SANTILLANA_BOOK_ACTIVITY_TYPES = %w[smart_book static_book].freeze

  GRADABLE_ACTIVITY_TYPES = %w[open_ended recording video_recording recording_v2
                               true_false_enhanced partner_chat virtual_chat video_virtual_chat
                               composition speech_rec_listen_repeat solo_video_recording
                               inline_open_ended group_chat ai_virtual_chat].freeze

  GRADABLE_QUESTION_TYPES = %i[recording open_ended virtual_chat partner_chat
                               video_virtual_chat true_false_enhanced
                               speech_rec_listen_repeat solo_video_recording
                               inline_open_ended group_chat ai_virtual_chat].freeze

  AI_GRADING_ACTIVITY_TYPES = %w[
    composition
    open_ended
  ].freeze

  STUDY_PLAN_TYPES = %w[study_plan_practice_test diagnostic_v2].freeze

  # Detects a page range that specifies an alternate vtext. On match,
  # Regexp.last_match(1) will contain the page range without the
  # specifier for the vtext number.
  # e.g. if applied to string 'v3(12-34)', returns '12-34'.
  ALTERNATE_VTEXT_PAGE_NUMBER_REGEXP = /v\d+\(([^\)]+)\)/.freeze

  has_many :assignments, as: :assignable
  has_many :attempts
  has_many :custom_rubrics, dependent: nil
  has_many :grading_sets
  has_many :notifications, extend: Notification::Dispatchable
  has_many :help_requests
  has_many :activity_notes
  has_many :course_library_activities
  has_many :grading_suggestions, class_name: 'AI::GradingSuggestion', dependent: :destroy
  has_many :overall_comments, class_name: 'AI::OverallComment', dependent: :destroy
  has_many :user_library_activities
  has_many :shared_library_activities, foreign_key: :source_activity_id
  has_many :study_plan_concepts, dependent: :destroy

  has_one(
    :standard_asset,
    -> { where(reference_type: 'Activity') },
    foreign_key: :reference_id,
    primary_key: :cms_activity_id,
    inverse_of: :activity,
    dependent: :destroy
  )

  # Concept and Lesson are defined as optional here because in the
  # QuestionBank subclass, they won't ever be set. However, there's no way
  # to redefine an association inside a subclass to change the the presence
  # validation to be optional just for the subclass. Instead, the optional
  # flag is added here and then presence validations are manually defined,
  # with an exception for QuestionBank instances.
  belongs_to :concept, optional: true
  belongs_to :lesson, optional: true
  belongs_to :license_group, class_name: 'Maestro::LicenseGroup', optional: true

  default_scope { where(question_bank_revision_id: nil) }

  scope :by_program, lambda { |program_id|
    joins(lesson: :unit).where('units.program_id = ?', program_id.to_s)
  }
  scope :unlisted, -> { where(toc_location: nil, component_name: 'Unlisted') }
  scope :has_toc_location, -> { where.not(toc_location: nil) }
  scope :has_toc_location_plus_unlisted, -> { has_toc_location.or(unlisted) }

  scope :hidden, lambda { |user, course|
    select { |act| !act.hidden?(course) } unless user.instructor?
  }

  validates_presence_of :cms_revision_id, unless: ->(obj) do
    obj.is_a?(InstructorCreatedActivity) || obj.is_a?(QuestionBank)
  end

  validates :concept, presence: true, unless: ->(obj) { obj.is_a?(QuestionBank) }
  validates :lesson, presence: true, unless: ->(obj) { obj.is_a?(QuestionBank) }

  after_save :set_denormalized_values
  after_commit :update_gradebook

  delegate :label, to: :lesson, prefix: true, allow_nil: true
  delegate :display_name, to: :lesson, prefix: true, allow_nil: true
  delegate :name, to: :concept, prefix: true, allow_nil: true
  delegate :name, to: :lesson, prefix: true, allow_nil: true
  delegate :lesson_combined_rank, to: :concept, allow_nil: true
  delegate :accent_bar?, :allow_missing_answers?, :diagnostic_feedback?,
           :hide_external_references?, :has_diagnostic?, :recording_activity?,
           :external_references, :language, :result_labels, :has_open_ended?,
           :rubric, :references,
           to: :content_object
  delegate :concept_combined_rank, to: :concept
  delegate(
    :formative_activities,
    :includes_solo_video_recording?,
    :includes_activity_type?,
    :reviewable_by_all_questions?,
    :show_answer_key?,
    to: :content_object,
    allow_nil: true
  )

  #define activity_type verification methods
  ACTIVITY_TYPES.each do |type|
    define_method("#{type}?") { activity_type == type }
  end

  def a11y_issues
    return {} if content_object.nil?

    @a11y_issues ||= content_object.a11y_issues
  end

  def chat_or_recording?
    partner_chat? || virtual_chat? || video_virtual_chat? ||
      recording_v2? || solo_video_recording_or_included_in_multipart_activity? ||
      group_chat?
  end

  def include_audio_recording?
    includes_activity_type?('virtual_chat') ||
      includes_activity_type?('video_virtual_chat') ||
      includes_activity_type?('recording_v2')
  end

  def include_video_recording?
    includes_activity_type?('partner_chat') ||
      includes_activity_type?('info_gap_partner_chat') ||
      includes_activity_type?('info_gap_partner_chat_v2') ||
      includes_activity_type?('solo_video_recording') ||
      includes_activity_type?('group_chat')
  end

  def partner_chat?
    %w[partner_chat info_gap_partner_chat info_gap_partner_chat_v2].include?(activity_type)
  end

  def solo_video_recording?
    activity_type == 'solo_video_recording'
  end

  def table_activity?
    activity_type == 'table_activity'
  end

  def group_chat?
    activity_type == 'group_chat'
  end

  def requires_chat?
    return partner_chat? || group_chat?
  end

  def multi_type?
    activity_type == 'multi_type'
  end

  def has_standards?
    if standards_test?
      AssessmentItem.where(assessment_id: cms_activity_id).any?
    else
      standard_asset&.standards.present?
    end
  end

  # Checks whether or not an activity is an exam, and, if
  # so, does it have guids associated with its questions.
  # Initially this was only true for Proficiency Assessments,
  # but now it is also true for some Progress Monitoring Assessments.
  def standards_test?
    # Ideally, this should be called when the object has already been parsed.
    activity_type == 'exam' && questions.any? { |q| q.try(:question_guid) }
  end

  # Need to differentiate between Proficiency and Progress Monitoring Assessments
  # for reporting purposes.
  def proficiency_assessment?
    standards_test? && self.concept.name == 'Proficiency Assessment'
  end

  def progress_monitoring_assessment?
    standards_test? && self.concept.name == 'Progress Monitoring Assessment'
  end

  def has_study_plan?
    STUDY_PLAN_TYPES.include?(activity_type)
  end

  def has_summative_study_plan?
    return false unless has_study_plan?

    study_plan_practice_test? || diagnostic_v2_summative?
  end

  def diagnostic_v2_summative?
    diagnostic_v2? && formative_activities.any?
  end

  def generate_content_json
    return content_json if content_json

    if valid_json_content? && content
      content
    else
      content_object.to_json(indent: 2).gsub('\\n', '')
    end
  end

  def valid_json_content?
    JSON.parse(content)
    true
  rescue StandardError
    false
  end

  # to be used by Services::TocActivityList
  def self.generate_unassigned_join(sections)
    sanitize_sql_for_conditions(["LEFT OUTER JOIN assignments ON activities.id = assignments.assignable_id
                                  AND assignments.section_id IN (?) AND assignments.assignable_type = 'Activity'", sections])
  end

  def has_multiple_versions?
    Activity.where(cms_activity_id: cms_activity_id).count > 1
  end

  def external?
    false
  end

  def reference_id
    if instructor_created?
      id
    else
      cms_activity_id
    end
  end

  def >(other)
    # We want to know if the activity has a greater revision_id than the other
    raise "Expected #{other} to be an activity" unless other.is_a?(Activity)

    self.revision_id > other.revision_id
  end

  def content_summary
    # self[:content_summary] is being used here to get the value of content_summary attribute without
    # calling object.content_summary.  Would self.read_attribute() be a better way to do this?

    # :quirks_mode => true is being used here to deal with empty string.
    # JSON.parse( ''.to_json ) raises JSON::ParserError: unexpected token at '""'.
    if self[:content_summary].present?
      JSON.parse(self[:content_summary], { quirks_mode: true, symbolize_names: true })
    else
      {}
    end
  end

  def question_summary
    content_summary.except(:dictionary_entries)
  end

  # question_summary is a hash like { fill_in_the_blanks: 5, multiple_choice: 10 }
  # the total number of questions is the sum of questions across all types.
  # in the case of a Smartbook this represents the number of subactivities
  def question_summary_count
    question_summary.values.sum
  end

  def dictionary_words_list
    content_summary[:dictionary_entries]
  end

  def notifications_by_user_and_section(user, section)
    notifications.by_user_and_section(user, section.id).newest_first if section
  end

  def create_changed_earned_points_notification(opts)
    notifications.dispatch('ChangedEarnedScore', opts)
  end

  # This method seems it is not being used
  def available_in_course?(course)
    course.program.components.include?(component_name)
  end

  def title_audio_filepath
    return unless content_object.respond_to?(:title_audio)

    content_object.title_audio&.media_item&.public_filename
  end

  def direction_line
    content_object && content_object.dl && content_object.dl.children.to_html
  end

  def direction_line_audio_filepath
    media_audio = if valid_json_content?
                    content_object.try(:dl_media_audio)
                  else
                    content_object&.direction_line_audio&.audio
                  end

    media_audio&.media_item&.public_filename
  end

  def listed?
    !unlisted?
  end

  def english?
    if question_bank?
      QuestionBank.find(id).question_bank_topic.language == 'english'
    else
      program.language_code.to_s == 'en'
    end
  end

  def media_lookup
    reference_media_lookup.merge(question_media_lookup)
  end

  def supports_ai_grading_feature?
    AI_GRADING_ACTIVITY_TYPES.include?(activity_type)
  end

  private def reference_media_lookup
    content_object_references.each_with_object({}) do |reference, memo|
      media_link = case reference.type
                   when 'image' then reference.image
                   when 'audio' then reference.audio
                   when 'video' then reference.video
                   end
      store_media_link(memo, media_link)
      merge_model_reference_media_items(reference, memo)
    end
  end

  private def merge_model_reference_media_items(reference, lookup)
    return unless reference.type == 'model'

    lookup.merge!(model_reference_media_items(reference))
  end

  private def content_object_references
    if has_sub_activities?
      content_object.activities.flat_map(&:references)
    else
      content_object.references
    end
  end

  private def question_media_lookup
    content_object_activities.each_with_object({}) do |activity, memo|
      if activity.respond_to?(:image_links)
        activity.image_links.each { |link| store_media_link(memo, link) }
      end

      if activity.respond_to?(:audio_links)
        activity.audio_links.each { |link| store_media_link(memo, link) }
      end

      if activity.respond_to?(:video_links)
        activity.video_links.each { |link| store_media_link(memo, link) }
      end
    end
  end

  private def content_object_activities
    content_object.activity_type == 'exam' ? content_object.activities : [content_object]
  end

  private def model_reference_body_media_items(reference)
    reference.image_links.each_with_object({}) do |image_link, memo|
      store_media_link(memo, image_link)
    end
  end

  private def model_reference_media_items(reference)
    model_reference_body_media_items(reference).tap do |memo|
      store_media_link(memo, reference.audio)
    end
  end

  private def store_media_link(aggregator, link)
    media_item = link&.media_item
    return unless media_item

    aggregator[media_item.id] = {
      src: media_item.public_filename,
      transcript: media_item.transcript
    }
  end

  def unlisted?
    component_name.blank? ||  component_name =~ /unlisted/i
  end

  def questions
    (content_object && content_object.questions) || []
  end

  def assessment?
    concept && concept.assessment?
  end

  def accessible_by_section?(section)
    return true unless section && assessment?
    assignment_on_section = assignments.by_section(section)
    if assignment_on_section.empty?
      false
    else
      assignment_on_section.first.shown?
    end
  end

  def instructor_graded_questions(activity_content = content_object)
    if activity_content.activities.present?
      activity_content.activities.map do |subactivity_content|
        instructor_graded_questions(subactivity_content)
      end.flatten
    elsif activity_content.is_a?(
            MaestroActivityEngine::ActivityContent::TableActivityContent
          )
      table_activity_instructor_graded_questions(activity_content)
    else
      activity_content.items.select { |item| instructor_gradable_type?(item) }
    end
  end

  private def table_activity_instructor_graded_questions(content)
    content.questions.flat_map do |question|
      if question.is_a?(
        MaestroActivityEngine::ActivityContent::TableActivity::TableInlineOpenEnded::Item
      )
        question.wols
      end
    end.compact
  end

  def has_composition_activities?
    content_object.activities.any? { |activity_content| activity_content.is_a?(MaestroActivityEngine::ActivityContent::CompositionContent) }
  end

  #move this into review work presenter
  def question_like_items
    sub_activities = content_object.activities.present? ? content_object.activities : [self.content_object]
    question_sets = []

    sub_activities.each do |sub_activity|
      questions = if sub_activity.respond_to?(:questions)
                    sub_activity.questions
                  else
                    sub_activity.items.select { |item| item.respond_to?(:question_number) }
                  end

      question_sets << {
                         activity: sub_activity,
                         questions: questions
                       }
    end
    question_sets
  end

  def title
    title = read_attribute(:title)
    title.html_safe if title
  end

  def student_display_title
    student_title.presence || "#{lesson_display_name} | #{concept_name}"
  end

  def activity_content
    if defined?(@activity_content)
      @activity_content
    else
      assign_new_content_instance
    end
  end

  def assign_new_content_instance
    @activity_content = if question_bank?
                          QuestionBankContent.new(question_bank_revision_id, id)
                        elsif instructor_created?
                          InstructorActivityContent.new(instructor_revision_id, cdn, id)
                        elsif preview?
                          PreviewActivityContent.new(cms_revision_id, program)
                        else
                          CmsActivityContent.new(cms_revision_id, cdn, id, program)
                        end
  end
  private :assign_new_content_instance

  delegate :content, :content_object, :content_filepath, :parse_content,
           :content_json, :content_json=, :parse_errors, :parse_warnings,
           :set_revision_id, :content=,
           to: :activity_content

  def ensure_correct_version(desired_revision_id)
    if gradable? && revision_id != desired_revision_id && desired_revision_id.present?
      set_activity_content(desired_revision_id)
      extend(PreviousRevision)
    end
  end

  def set_activity_content(desired_revision_id)
    if instructor_created?
      self.instructor_revision_id = desired_revision_id
    else
      self.cms_revision_id = desired_revision_id
    end

    # re-assign @activity_content with a new object and re-parse
    assign_new_content_instance
    parse_content
    self.has_rubric = content_object.has_rubric?
  end
  private :set_activity_content

  def instructor_created?
    instructor_revision_id.present? || is_a?(InstructorCreatedActivity)
  end

  def question_bank?
    question_bank_revision_id.present? || is_a?(QuestionBank)
  end

  def lang_code
    if question_bank?
      Language.language_hash.key(QuestionBank.find(id).question_bank_topic.language.titlecase)
    else
      program.language_code
    end
  end

  def is_owner?(instructor)
    instructor_created? && (instructor.id == instructor_id)
  end

  def revision_id
    if question_bank?
      question_bank_revision_id
    elsif instructor_created?
      instructor_revision_id
    else
      cms_revision_id
    end
  end

  def lesson_and_strand_label
    "#{lesson_label} | #{lesson_strand_label}"
  end

  # rubocop:disable Rails/OutputSafety
  def strand_and_title_label
    if strand
      strand_name = strand.name.capitalize
      "#{strand_name}: #{title}".html_safe
    else
      title.html_safe
    end
  end
  # rubocop:enable Rails/OutputSafety

  def lesson_strand_label
    return '' unless strand
    strand_name = strand.name
  end

  def strand_singular_label
    strand && strand.singular_label
  end

  def instructor_graded?
    GRADABLE_ACTIVITY_TYPES.include?(activity_type) || activity_contains_gradable_questions?
  end

  private def activity_contains_gradable_questions?
    question_summary.present? && (GRADABLE_QUESTION_TYPES & question_summary.keys).any?
  end

  def instructor_gradable?
    # the second part of this is a temporary filter
    ['instructor', 'mixed'].include?(grading_method) && activity_type != 'recording'
  end

  def strictness?
    case activity_type
    when 'fill_in_the_blanks' then true
    when 'interactive_video' then has_diagnostic?
    else false
    end
  end

  def read_only=(read_only)
    @read_only = read_only
  end

  def read_only?
    @read_only.nil? ? false : @read_only
  end

  def gradable?
    submittable?
  end

  private def completable_activity_types
    %w[
      hotspots
      learning_engine
      quick_check_category_matching
      quick_check_drag_and_drop
      quick_check_multiple_choice
      quick_check_word_ordering
      vocabulary_tutorial
      vocabulary_tutorial_v2
    ]
  end

  def not_gradable_or_completable?
    if gradable?
      false
    else
      completable_activity_types.exclude?(activity_type)
    end
  end

  def program
    lesson.program
  end

  def lesson_label
    lesson&.label || ''
  end

  def label
    title
  end

  def column_index
    self.class.column_index(id)
  end

  def self.find_by_cms_activity_id_in_program(cms_activity_id, program_id)
    joins([:lesson => :unit])
    .where(activities: {cms_activity_id: cms_activity_id},
           units: {program_id: program_id})
    .where('activities.toc_location IS NOT NULL OR
           (activities.toc_location IS NULL AND component_name = "Unlisted")')
    .first
  end

  def self.activity_types_mapping
    ACTIVITY_TYPES.each_with_object({}) do |activity_type, hsh|
      hsh[activity_type.to_sym] = humanize_activity_type(activity_type)
    end
  end

  def self.find_by_type_and_id(activity_id, activity_type)
    case activity_type
    when 'Activity'
      return find_by_id(activity_id)
    when 'ExternalActivity'
      return ExternalActivity.find_by_id(activity_id)
    else
       raise "Unknown activity type #{activity_type}"
    end
  end

  def self.find_all_by_toc_location(toc_location)
    raise 'Activity.find_all_by_toc_location cannot be called, please use Services::TocActivityList.all_by_toc_location'
  end

  def self.column_index(id)
    "a#{id}"
  end

  def external_activity?
    false
  end

  def compare(a, b)
    #need way to handle ExternalActivities here
    if a.lesson.unit && b.lesson.unit
      unit_comparator = a.lesson.unit.rank <=> b.lesson.unit.rank
      return unit_comparator if unit_comparator != 0
    end

    lesson_comparator = a.lesson.rank <=> b.lesson.rank
    return lesson_comparator if lesson_comparator != 0

    toc_location_rank_comparator = a.toc_location_rank_in_lesson <=> b.toc_location_rank_in_lesson
    return toc_location_rank_comparator if toc_location_rank_comparator != 0

    a.toc_location_rank <=> b.toc_location_rank
  end
  private :compare

  def self.filename_from_revision_id(revision_id)
    id_string = sprintf("%08d", revision_id)
    "rev_#{id_string[0..-5]}/#{id_string[-4..-1]}.xml"
  end

  def self.filepath_from_revision_id(revision_id, instructor_created = false, cdn = true)
    activity_type_dir = instructor_created ? 'instructor_activities' : 'activities'

    # The cdn has a shorter filepath to the activity xml.
    # When the server is live, we use the shorter, cdn path.
    # For all m3 environments, the cdn param is meant to be the state of the
    # cdn attribute for the activity object that we need the filepath for.
    # If it is true, return the cdn filepath.
    if Rails.env.live? || cdn
      File.join(activity_type_dir, filename_from_revision_id(revision_id))
    else
      # If this is not a live m3 and cdn is false, return the longer filepath.
      env_dir = "#{Rails.env}#{ENV['TEST_ENV_NUMBER']}" # support parallel cukes
      File.join("datafiles", env_dir, activity_type_dir, filename_from_revision_id(revision_id))
    end
  end

  def self.all_grading_methods
    [
      ['Instructor','instructor' ],
      ['Auto','auto' ],
      ['Mixed','mixed' ]
    ]
  end

  def self.humanize_activity_type(str)
    #strip _v2 and _same postfixies
    old_type = str.to_s.gsub(/_same$|_v2$/i, '')
    case old_type
    when 'ai_virtual_chat' then 'AI Chat'
    when 'audio_hotspots' then 'Talking picture'
    when 'solo_video_recording' then 'Video Recording'
    when 'tutorial_vocab' then 'Tutorial vocabulary'
    when 'tutorial_vocab_html5' then 'Tutorial vocabulary'
    else
      old_type.humanize
    end
  end


  def has_mixed_grading_method?
    content_object && content_object.grading_method == 'mixed'
  end

  def has_sub_activities?
    content_object.activities.present?
  end

  def info_gap_partner_chat_v2_with_subactivities?
    activity_type == 'info_gap_partner_chat_v2' && has_sub_activities?
  end

  def has_bonus?
    has_sub_activities? && content_object.activities.any?(&:is_bonus?)
  end

  def sub_activities
    content_object.activities
  end

  def auto_graded?
    grading_method == 'auto'
  end

  def mixed_grading?
    grading_method == 'mixed'
  end

  def assigments_on_same_day(assignments_array, day)
    assignments_array.select{ |assignment| assignment.assignable == self && assignment.due_date == day }
  end

  def <=>(b)
    compare(self, b)
  end

  def items_count
    question_summary.inject(0){|sum,x| sum + x[1] }
  end

  def strand
    return nil unless lesson
    @strand ||= lesson.strand_for_toc_location(toc_location)
  end

  def sub_strand
    return nil unless lesson
    @substrand ||= lesson.substrand_for_toc_location(toc_location)
  end

  def list_header
    header = ''
    if lesson && toc_location
        header << "#{lesson.display_name}"

        strand_name = strand.name if strand
        header << " | #{strand_name}" if strand_name

        substrand = lesson.substrand_for_toc_location(toc_location)
        substrand_name = substrand.name if substrand
        header << " | #{substrand_name}" if substrand_name
    end
    header.html_safe
  end

  def vtext_link=(linker)
    # insert vtext link into the content_object for link_vtext activities
    if activity_type == 'link_vtext'
      content_object.link_vtext.vtext_url = linker.link
    end
  end

  def first_page
    page_range.split('-').first
  end

  # When the page specifies an alternate vtext, returns the page range
  # without the specifier for the vtext number.
  # e.g. if the page value is 'v3(12-34)', returns '12-34'.
  def page_range
    page_string = page.to_s
    if page_string =~ ALTERNATE_VTEXT_PAGE_NUMBER_REGEXP
      Regexp.last_match(1)
    else
      page_string
    end
  end

  def icon
    change_textbook_if_vol = lambda do |icon|
      if program.vista_online_learning && icon == 'textbook'
        'vol_' + icon
      else
        icon
      end
    end

    @icon ||= self[:icon].to_s.split(',').map do |icon|
      change_textbook_if_vol.call(icon)
    end.join(',')
  end


  # need to always sent Activity to gradebook not InstructorCreatedActivity
  def gradebook_class_name
    "Activity"
  end

  def smart_book?
    activity_type == 'smart_book'
  end

  # if the activity itself is a shared IGC activity with a
  # SharedLibraryActivity record that has an is_shared attribute set to true
  def is_shared_copy?
    SharedLibraryActivity.find_by(activity_id: id)&.is_shared
  end

  # if the activity is the source for a shared IGC activity and its corresponding
  # SharedLibraryActivity record exists and its is_shared attribute is set to true
  def is_shared_source?
    # TODO: shared_library_activities.last&.activity_id.present?
    shared_library_activities.last&.is_shared?
  end

  # if SharedLibraryActiviy record exists
  def is_pending_share?
    shared_library_activities.last.present?
  end

  def santillana?
    SANTILLANA_BOOK_ACTIVITY_TYPES.include?(activity_type)
  end

  def includes_solo_video_recording?
    content_summary[:solo_video_recording].present?
  end

  def includes_inline_open_ended?
    content_summary[:inline_open_ended].present?
  end

  def solo_video_recording_or_included_in_multipart_activity?
    solo_video_recording? || includes_solo_video_recording?
  end

  def rubric
    content_object.rubric || content_object.external_rubric&.rubric
  end

  def has_external_rubric?
    content_object.external_rubric&.rubric.present?
  end

  def has_inline_rubric?
    content_object.respond_to?(:inline_rubric) &&
      content_object.inline_rubric&.first.rubric.present?
  end

  def show_rubric?
    # if activity has rubric and is included in the
    # activity types with rubic
    has_rubric? &&
      MaestroActivityEngine::ActivityContent::Content::RUBRIC_ACTIVITY_TYPES.include?(activity_type)
  end

  def creator
    User.unscoped.find(instructor_id)
  end

  def creator_name
    creator.full_name
  end

  def hidden?(course)
    course_library_activities.where(course: course)&.last&.hidden == true
  end

  private def set_denormalized_values
    return if denormalized_values.empty?

    raise ActiveRecordError, 'can not update on a new record object' unless persisted?

    # rubocop:disable Rails/SkipsModelValidations
    # Use update_all with a condition that id matches current record id
    # to update all the attributes with a single sql query, bypassing the
    # callback change (otherwise we'd get an endless loop).
    self.class.unscoped.where(
      self.class.primary_key => id
    ).update_all(denormalized_values)
    # rubocop:enable Rails/SkipsModelValidations

    # Since the denormalized values get updated in the database directly
    # using sql, the current record won't reflect the new values unless it
    # gets reloaded. Instead of reloading, it's easier to just assign the
    # attributes to the current instance.
    denormalized_values.each do |k, v|
      write_attribute_without_type_cast(k.to_s, v)
    end
  end

  private def denormalized_values
    return @denormalized_values if @denormalized_values.present?
    @denormalized_values = values_from_content_object
                           .merge(set_singular_label)
                           .merge(set_minutes_to_complete)
  end

  private def values_from_content_object
    # For has_vhl_image we are excluding instructor generated content (IGC activities)
    # since we only seek to determine if the vhl activities have image media items or not.
    if content_object.present?
      {
        activity_type: content_object.activity_type,
        content_summary: content_object.content_summary.to_json,
        grading_method: content_object.grading_method,
        has_rubric: content_object.has_rubric?,
        has_vhl_image: cms_revision_id.present? && content_object.has_image?,
        max_attempts: content_object.max_attempts,
        points_possible: set_points_possible,
        randomizable: content_object.randomizable?,
        submittable: content_object.submittable?
      }
    else
      {}
    end
  end

  private def set_minutes_to_complete
    return {} if content_object.blank?

    minutes = ActivityTimeEstimateSetter.new(
      activity_type: content_object.activity_type
    ).time_to_complete
    { minutes_to_complete: minutes }
  end

  private def set_singular_label
    assessment? && strand.present? ? { singular_label: strand.singular_label } : {}
  end

  private def set_points_possible
    if content_object.submittable?
      content_object.points_possible
    else
      # unsubmittable activities are worth 1 point
      1
    end
  end

  def preview?
    false
  end

  module PreviousRevision
    delegate :grading_method, :activity_type, :points_possible, to: :content_object
  end
end

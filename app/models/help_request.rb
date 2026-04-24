class HelpRequest < ApplicationRecord
  include EmojiRemovable

  belongs_to :user
  belongs_to :program
  belongs_to :activity
  # belongs_to is optional because content problem reports can be for section 0.
  belongs_to :section, optional: true
  # belongs_to is optional because requests aren't yet processed by any
  # instructor when initially created.
  belongs_to :instructor, class_name: 'User', foreign_key: 'processed_by', optional: true

  before_save :truncate_http_referer, if: :http_referer_changed?

  REQUEST_TYPES = %w(request_help request_review report_technical_problem report_content_problem)
  INSTRUCTOR_RESPONDABLE_TYPES = %w(request_help request_review)
  REPORTED_PROBLEM_TYPES = %w(report_technical_problem report_content_problem)

  SEVERITY_LEVELS = { 1 => "I cannot continue with this task",
                      2 => "This is a problem that I can work around",
                      #3 => "This is annoying me",
                      4 => "I'm just submitting a suggestion" }

  # When rendering json to display help requests inside an activity, we don't
  # need all the tech-support-related fields, like flash version and browser
  # type. We also want the student name to be displayed to the instructor.
  ACTIVITY_JSON_OPTIONS = {
    methods: %i[instructor_name student_name],
    only: %i[
      activity_id
      activity_state
      created_at
      helpable_item_id
      helpable_item_type
      id
      instructor_comment
      processed_at
      program_id
      read_by_student
      request_type
      section_id
      status
      student_comment
      user_id
    ]
  }.freeze

  validates_presence_of :user_id
  validates_presence_of :program_id
  validates_presence_of :activity_id
  validates_inclusion_of :request_type,
                         in: REQUEST_TYPES,
                         message: "'%{value}' must be one of: #{REQUEST_TYPES.join(', ')}"

  scope :by_section_and_activity, (lambda do |section, activity|
    where(section_id: section, activity_id: activity)
  end)
  scope :unprocessed, -> { where(status: 'submitted') }
  scope :processed, -> { where("status <> 'submitted'") }
  scope :instructor_respondable, -> { where(request_type: INSTRUCTOR_RESPONDABLE_TYPES) }
  scope :reported_problems, -> { where(request_type: REPORTED_PROBLEM_TYPES) }
  scope :by_request_type, ->(request_type) { where(request_type: request_type) }
  scope :by_user, ->(user) { where(user_id: user) }
  scope :by_section, ->(section) { where(section_id: section) }

  scope :by_user_and_activity, (lambda do |user, activity|
    where(user_id: user, activity_id: activity)
  end)

  scope :by_section_user_and_activity, (lambda do |section, user, activity|
    where(section_id: section, user_id: user, activity_id: activity)
  end)

  scope :for_question_label, (lambda do |question_label|
    where(
      "(helpable_item_id = ? or helpable_item_id like ?)",
      question_label,
      "#{question_label}\\_%"
    )
  end)

  scope :include_students, -> { includes(:user) }
  scope :include_users, -> { includes(:user, :instructor) }
  scope :include_location, -> { includes(activity: { concept: { lesson: :unit } }) }

  def self.by_section_activity_and_request_type(section, activity, request_type)
    by_section_and_activity(section, activity).by_request_type(request_type)
  end

  def student_name
    user && user.full_name
  end

  def instructor_name
    instructor && instructor.full_name
  end

  def processed?
    ['responded', 'denied'].include? status
  end

  def problem_report?
    REPORTED_PROBLEM_TYPES.include?(request_type)
  end

  def technical_problem?
    request_type == 'report_technical_problem'
  end

  def content_problem?
    request_type == 'report_content_problem'
  end

  def self.by_active_enrollments
    joins('INNER JOIN enrollments ON enrollments.section_id = help_requests.section_id AND ' \
           'enrollments.user_id = help_requests.user_id').merge(Enrollment.active)
  end

  def self.instructor_respondable_by_user_and_section(user, section)
    instructor_respondable.by_user(user).by_section(section).by_active_enrollments
  end

  def self.instructor_respondable_by_section_and_activity(section, activity)
    instructor_respondable.by_section_and_activity(section, activity)
  end

  def self.instructor_respondable_by_section_user_activity_and_question(section, user, activity, question = nil)
    results = instructor_respondable.by_section_user_and_activity(section, user, activity)
    if question && !question.blank?
      results.for_question_label(question)
    else
      results
    end
  end

  def self.count_unprocessed_by_request_type_section_and_students(request_type, section, student, opts = {})
    results = unprocessed.by_request_type(request_type)
                         .by_section(section)
                         .by_user(student)
                         .by_active_enrollments
    results = opts[:select] ? results.select(opts[:select]) : results
    results = opts[:group] ? results.group(opts[:group]) : results
    results.count
  end

  def self.processed_instructor_respondable_by_section_and_activity(section, activity)
    processed.instructor_respondable.by_section_and_activity(section, activity)
  end

  def self.reported_problems_by_section(section)
    # Argument section could a scope. If so we need to avoid causing a nested subquery.
    section = section.to_a if section.is_a?(ActiveRecord::Relation)
    reported_problems.by_section(section)
  end

  def dispatch_notification
    activity.notifications.dispatch('HelpRequestResponse', { section: section, user: user })
  end

  def self.destroy_review_requests_for(user, section, activity)
    by_user_and_activity(user, activity).by_section(section).by_request_type('request_review').destroy_all
  end

  def truncate_http_referer
    if self.http_referer.length > 255
      self.http_referer = self.http_referer.slice(0, 255)
    end
  end

  def attributes_to_clean
    [:student_comment, :instructor_comment]
  end
end

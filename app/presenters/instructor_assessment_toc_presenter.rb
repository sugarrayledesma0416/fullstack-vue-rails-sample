class InstructorAssessmentTocPresenter
  include ApplicationHelper
  include Lti::TocDeepLinking
  include InstructorTocPresentation
  # "Common" means shared between Supersite Junior and non-Supersite Junior
  include TocPresenterCommon
  # "Standard" means "not Supersite Junior"
  include StandardTocPresentation
  include InstructorAssignableActivity
  include TimeHandler
  include AssessmentAvailabilityChecker

  attr_accessor :activities,
                :current_focus,
                :current_program,
                :current_user,
                :lesson,
                :program,
                :sections,
                :session

  def initialize(program,
                 current_focus,
                 user,
                 req_params,
                 session)
    raise 'not all parameters are valid' if !program ||
                                            !user||
                                            !req_params

    self.current_user = user
    self.current_focus = current_focus
    self.program = program
    self.sections = current_focus.sections
    self.course = sections.first.course if sections.present?
    self.session = session
    @req_params = req_params
    @saved_location = session[:saved_location]
  end

  def reference_section_id
    return sections.first.id if has_sections?
    '0'
  end

  def assignable_view?
    has_sections?
  end

  def display_lesson
    @display_lesson ||= program.best_display_lesson(
      req_params[:display_lesson],
      req_params[:start_unit],
      units,
      trial_access?
    ).extend(LessonWithAssessmentStrands)
  end

  def current_strand
    @current_strand ||= toc_location || relevant_strand
  end

  def current_topic
    @current_topic ||= toc_location || relevant_topic
  end

  def activities
    return [] if display_lesson.strands.empty?
    @activities ||= ::Activity
                    .where(:id => activities_to_show_ids)
                    .where(hide_from_my_content: false)
                    .order('instructor_revision_id DESC, toc_location_rank ASC')
  end

  def base_url(options={})
    Rails.application.routes.url_helpers.instructor_assessments_path(program.id,options)
  end

  def base_url_params
    {:program_id => program.id}
  end

  def assessment_availability(activity)
    label = (activity.strand_singular_label.present? && activity.strand_singular_label || 'assessment').capitalize
    availability_status(activity, :shown?)
  end

  def assessment_grade_availability(activity)
    availability_status(activity, :assessment_grade_available?)
  end

  def max_attempts(activity)
    assignments = assignments_for_activity(activity)
    MaxAttemptPolicy.new(activity, assignments.first).max_attempts
  end

  def has_assignments_for?(activity)
    assignments_for_activity(activity).present?
  end

  def assignments_for_activity(activity)
    return [] if assignments.blank?
    assignments.select{ |assignment| assignment.assignable == activity }
  end
  private :assignments_for_activity

  def show_release_link_for?(activity)
    assignments_for_activity(activity).any?{ |assignment| assignment.show_assessment == 'I release it' }
  end

  def show_grades_release_link_for?(activity)
    assignments_for_activity(activity).any?{ |assignment| assignment.grade_availability == :on_release }
  end

  def show_answers_release_link_for?(activity)
    assignments_for_activity(activity).any?{ |assignment| assignment.answer_availability == :on_release }
  end

  def reference_section
    sections.first
  end

  def availability_status_for(activity)
    assignments = assignments_for_activity(activity)
    return '' if assignments.empty? || assignments.have_different_values_for?( :shown? )
    # we want to leave this column blank if one assignment is shown and another isn't
    # so we don't show "Quiz availability Varies | Varies"

    if assignments.have_different_values_for?( :show_at )
      'Varies'
    else
      format_date_time(assignments.first.show_at, :compact_date_and_time, reference_section.time_zone)
    end
  end

  def grade_availability_status_for(activity)
    assignments = assignments_for_activity(activity)
    return '' if assignments.empty? || assignments.have_different_values_for?( :assessment_grade_available? )
    # we want to leave this column blank if grades are available for one assignment but not for another
    # so we don't show "Grade availability Varies | Varies"

    if assignments.have_different_values_for?( :grade_availability )
      'Varies'
    else
      case assignments.first.grade_availability
      when :never       then "Never"
      when :on_grading  then "After grading"
      when :on_specific_date
        if assignments.have_different_values_for?( :grades_available_at )
          'Varies'
        else
          formatted_date(assignments.first.grades_available_at)
        end
      when :on_due_date
        if assignments.have_different_values_for?( :due_date_time )
          'Varies'
        else
          formatted_date(assignments.first.due_date_time)
        end
      else
        ""
      end
    end
  end

  def toc_path(*args)
    Rails.application.routes.url_helpers.instructor_assessments_path(program.id, *args)
  end

  # @return Yes, Varies, No
  def password_protected?(activity)
    assignments = assignments_for_activity(activity)
    assignments.map(&:has_password?).vary? and return 'Varies'
    assignments.first.has_password? ? 'Yes' : 'No'
  end

  def time_limit_for(activity)
    assignments = assignments_for_activity(activity)
    assignments.map(&:time_limit).vary? and return 'Varies'
    assignments.first.time_limit == 0 ? 'None' : assignments.first.time_limit
  end

  def allow_assessment_randomization?(activity)
    program.allow_assessments_randomization? && activity.randomizable?
  end

  def randomize_per_student(activity)
    assignments = assignments_for_activity(activity)
    return 'Varies' if assignments.map(&:randomize_per_student?).vary?
    assignments.first.randomize_per_student? ? 'Yes' : 'No'
  end

  def focused_on_course?
    current_focus.type == 'course'
  end

  def set_times_title
    'Set times in Section view' if focused_on_course?
  end

  def pluralize(int, singular, plural)
    "#{int} #{int == 1 ? singular : plural}"
  end

  # this method is used on the creation of the toc carousel lesson links.
  # for the activites toc we use a more complex version since the strand can
  # differ from lesson to lesson. But for assessment we are ok with using the current_strand.
  def toc_location_for_lesson(lesson)
    current_strand
  end

  def show_shared_content_option
    school = current_focus.course.school
    school.enterprise_for_program?(program.id)
  end

  def new_activity_link_presenter(view)
    Instructor::CreatedActivity::NewActivityLinkAssessmentPresenter.new(view, self)
  end

  private def toc_location
    display_lesson.extend(ParallelLocationFinding).parallel_toc_location(
      req_params[:toc_location]
    )
  end

  private def relevant_strand
    most_relevant_strand = display_lesson.extend(ParallelLocationFinding)
                                         .most_relevant_strand(
                                           req_params[:toc_location],
                                           saved_location
                                         )
    most_relevant_strand && most_relevant_strand.location.to_s
  end

  private def relevant_topic
    display_lesson.extend(ParallelLocationFinding).most_relevant_topic(
      req_params[:toc_location],
      req_params[:start_strand],
      req_params[:start_topic],
      saved_location
    )
  end

  def show_release?(assignment, type)
    case type
    when 'assessment_release' then assignment.show_at.blank?
    when 'grade_release'      then assignment.grades_available_at.blank?
    end
  end
  private :show_release?

  def formatted_date(date)
    format_date_time(date, :compact_date_and_time, reference_section.time_zone) if date.present?
  end
  private :formatted_date

  def has_sections?
    sections && !sections.empty?
  end
  private :has_sections?
end

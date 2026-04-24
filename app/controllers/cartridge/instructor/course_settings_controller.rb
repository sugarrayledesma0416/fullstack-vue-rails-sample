class Cartridge::Instructor::CourseSettingsController < ApplicationController
  helper MaestroActivityEngine::ActivitiesHelper
  include CartridgeViewable

  before_action :require_user
  before_action :require_instructor
  before_action :assign_section

  SCORING_RULESET_ATTRIBUTES =
    %i[ignore_accents ignore_capitalization ignore_punctuation].freeze

  def update
    begin
      update_course_settings(course, raise_on_error: true)
      flash[:notice] = 'The course settings have been updated.'
      # now update the other courses with the same context id;
      # don't want to do it all at once because we need to check validity
      # and gather error messages from just one course and category
      update_related_courses
    rescue ActiveRecord::RecordInvalid
      flash[:errors] = (course.errors.full_messages + @category.errors.full_messages).join(', ')
    end
    redirect_to instructor_grading_styles_path(course.program_id, params[:activity_id], task_type: params[:task_type])
  end

  def update_course_settings(course, raise_on_error: false)
    course.assign_attributes(course_params)
    @category = course.categories.first
    assign_category_attributes(@category)
    ActiveRecord::Base.transaction do
      update_assignments_due_date(course)
      course.save!
      @category.save!
    end
  rescue ActiveRecord::RecordInvalid
    raise if raise_on_error
  end

  private def assign_section
    @section = Section.find(params[:section_id])
  end

  private def categories_params
    params[:course].extract!(:category).require(:category)
  end

  private def scoring_ruleset_attributes
    %i[ignore_accents ignore_capitalization ignore_punctuation]
  end

  private def switch_scoring_ruleset(ruleset_values)
    # Always invert the attributes because the attrs on the server side
    # are negative (ignore_accents instead of Accent marks count).
    # The wording 'Accent marks count', 'Capitalization counts' and
    # 'Punctuation counts' was obtained from the course wizard.
    SCORING_RULESET_ATTRIBUTES.each do |attribute|
      ruleset_values[attribute] = !ActiveModel::Type::Boolean.new.cast(ruleset_values[attribute])
    end
    ruleset_values
  end

  private def assign_category_attributes(category)
    category.assign_attributes(category_attributes)
  end

  private def course_params
    return @course_params if defined? @course_params

    @course_params = params.require(:course).permit(%i[allow_audio_transcripts
                                                         video_subtitle_languages
                                                         video_transcript_languages
                                                         end_date])
    begin
      @course_params[:end_date] = Date.strptime(@course_params[:end_date], '%m-%d-%Y')
    rescue StandardError
      @course_params[:end_date] = nil
    end
    @course_params
  end

  # strip out the category settings that we need to update the category;
  # previously it was tied to a category id but we need to look at a category
  # for each course so we don't need to retrieve the category for the one
  # course anymore
  private def category_attributes
    return @category_attributes if defined? @category_attributes

    categories_params.each_pair do |category_id, category_data|
      @category_data = category_data
      @max_attempts_attr = category_data.permit(:max_attempts)
      @scoring_ruleset_attrs = category_data[:scoring_ruleset].permit(SCORING_RULESET_ATTRIBUTES)
      @scoring_ruleset_values = switch_scoring_ruleset(@scoring_ruleset_attrs)
      @category_attributes = @max_attempts_attr.merge(scoring_rulesets_attributes: [@scoring_ruleset_values])
    end
    @category_attributes
  end


  private def update_assignments_due_date(course)
    return if assignment_due_date.nil?

    course.assignments.each do |assignment|
      # We use #update_column to bypass the assignment validations.
      # We need that because the assignment's validation checks the due date
      # against the course end date (that has not yet been updated).
      # And if we update the course end date before the assignments due dates,
      # the course validations fail because it checks the course end date against
      # the assignments' due dates that hav not yet been updated.
      assignment.update_column(:due_date, assignment_due_date)
    end
  end

  private def course
    @course ||= @section.course
  end

  private def assignment_due_date
    @assignment_due_date ||= course_params[:end_date]
  end

  private def update_related_courses
    related_courses.each do |course|
      update_course_settings(course)
    end
  end

  private def related_courses
    # grab all the courses for this context id
    # retrieve the context_id for this section;
    # then retrieve all courses that have the same
    # context_id (different programs)
    ccd = Cartridge::CourseContextDetail.find_by!(
      section_id: @section.id)
    ccds = Cartridge::CourseContextDetail.where(lms_context_id: ccd.lms_context_id, school: @section.course.school.id).includes(:course)
    courses = ccds.map(&:course)
    courses - [course]  unless courses.empty?
  end
end

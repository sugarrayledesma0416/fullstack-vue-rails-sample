class AssignmentFilterPresenter
  include InstructorAssignableActivity
  # "Common" means shared between Supersite Junior and non-Supersite Junior
  include TocPresenterCommon
  # "Standard" means "not Supersite Junior"
  include StandardTocPresentation
  include InstructorTocPresentation

  attr_reader :course, :user, :program
  alias_method :current_user, :user

  def initialize(program, sections,
                 course, user,
                 focus, current_activities_count)

    @program = program
    @sections = sections
    @course = course
    @user = user
    @focus = focus
    @current_activities_count = current_activities_count
  end

  def lessons
    @lessons ||= program.browsable_lessons(visible_lessons)
  end

  def visible_lessons
    program.visible_lessons(@user.can_view_unreleased_units?)
  end

  def components
    @components ||= ComponentCodes.new(program).labels
  end

  def content_types
    @content_types ||= program.content_types_selection_list
  end

  def activity_types
    @activity_types ||= ActivityTypeOptionList.new(program.lessons, user).sorted_options
  end

  class ActivityTypeOptionList
    attr_accessor :lessons, :user

    def initialize(program_lessons, user)
      self.lessons = program_lessons
      self.user = user
    end

    def sorted_options
      options_list.sort{ |a, b| a[0] <=> b[0]  }
    end

    private def options_list
      activity_types.inject({}) do |memo, activity_type|
        display_name = Activity.humanize_activity_type(activity_type)
        if memo.has_key?(display_name)
          memo[display_name] << ",#{activity_type}"
        else
          memo[display_name] = activity_type
        end
        memo
      end
    end

    private def activity_types
      # we use the TocActivituList without a course param, because we want to get the activity_type
      # of all activities.
      Activity.where(
        id: Services::TocActivityList.all_for_lesson(lessons, current_user: user)
      ).distinct.pluck(:activity_type).compact
    end
  end

  def previous_sections
    @previous_sections ||= all_sections_for_program - @focus.sections
  end

  def all_sections_for_program
    @user.all_sections_for_program(program).reject{ |section| section.course.nil? }
  end
  private :all_sections_for_program

  def filter
    @filter ||= AssignmentFilter.find_or_create(@user, @course, lessons)
  end

  def strands
    @strands ||= filter.lesson ? filter.lesson.strands : []
  end

  def categories
    @categories ||= filter.previous_section ?  filter.previous_section.categories : []
  end

  def weeks
    @weeks ||= filter.previous_section ?  filter.previous_section.weeks_covered : []
  end

  def start_date
    @start_date ||= filter.start_date
  end

  def end_date
    @end_date ||= filter.end_date
  end

  # It seems this method is not used, if it is, it might have a bug since it
  # removes the IGC activities with the condition 'AND activities.instructor_revision_id IS NULL'
  def unassigned_activities
    @unassigned_activities ||= filter.filter(unfiltered_activities, @current_activities_count)
  end
  alias_method :activities, :unassigned_activities

  def summary_sentences
    @summary_sentences ||= build_summary_sentences
  end

  def grouped_unassigned_activities
    filter.group_by_lesson_plus_concept_and_sort(unassigned_activities)
  end

  def build_summary_sentences
    {:location => build_location_sentence, :previously_assigned => build_assignment_sentence, :properties => build_properties_sentence}
  end

  def build_location_sentence
    SummarySentencePresenter.new('location', :filter => filter, :strands => strands).sentence
  end

  def build_assignment_sentence
    SummarySentencePresenter.new('previously assigned', :filter => filter ).sentence
  end

  def build_properties_sentence
    SummarySentencePresenter.new('properties', :filter => filter ).sentence
  end

  def lesson_name_class(activity_group)
    if any_assignable?(activity_group)
      ''
    else
      'unassignable_lesson'
    end
  end

  private def unfiltered_activities
    toc_activity_list = Services::TocActivityList.all_unassigned_by_program(
      program.id,
      sections: @sections,
      current_user: user
    )
    Activity.includes(:concept, :lesson).where(id: toc_activity_list).order('activities.lesson_id, activities.toc_location_rank')
  end
end

# "Standard" indicates "not Supersite Junior"
module StandardTocPresentation
  extend ActiveSupport::Concern

  UnitForSelector = Struct.new(:multi_lesson, :text, :icon_filename, :chinese_labels, :lessons)
  LessonForSelector = Struct.new(:text, :path, :selected)
  Selector = Struct.new(:units, :unit_range_toggle_path, :unit_range_label)

  # Normally the reverse sort on instructor_revision_id ensures that
  # instructor-created activities are shown at the top. However, for
  # rubric editing, the instructor-created copy should be shown in the
  # normal toc position instead, so NULL is returned instead of the
  # instructor_revision_id value (only for sorting purposes).
  ACTIVITY_SORT = <<~SQL.squish.freeze
    if(
      (has_rubric is not NULL AND instructor_revision_id is not NULL),
      NULL,
      instructor_revision_id
    ) desc,
    toc_location_rank ASC
  SQL

  def activities
    # assigning display lesson to the returned activities to reduce objects
    # created and reducing parsing of lesson xml
    @activities ||= ::Activity
                    .where(id: activities_to_show_ids)
                    .where(hide_from_my_content: false)
                    .includes(:course_library_activities)
                    .order(Arel.sql(ACTIVITY_SORT))
                    .hidden(current_user, course)
                    .each { |act| act.lesson = display_lesson }
  end

  def strand_url(start_unit, display_lesson, toc_location)
    all_units_param = course_units_link[:current_state_url_options] || {}
    base_url( { :start_unit => start_unit, :display_lesson => display_lesson, :toc_location => toc_location }.merge(all_units_param) )
  end

  def lessons_for(unit)
    @lessons ||= Hash.new
    @lessons[unit.id] ||= unit.lessons
  end

  def display_lesson
    @display_lesson ||= program.best_display_lesson(
      req_params[:display_lesson],
      req_params[:start_unit],
      units,
      trial_access?
    )
  end

  def trial_access?
    current_user&.instructor? && program && access_guardian.has_unexpired_demo_access?
  end

  def display_lesson?(lesson)
    display_lesson == lesson
  end

  def display_unit
    display_lesson.unit
  end

  def display_unit?(unit)
    display_unit == unit
  end

  def display_unit_viewable?
    display_unit.released? || current_user.can_view_unreleased_units?
  end

  def current_strand
    @current_strand ||= display_lesson.extend(ParallelLocationFinding).current_strand(req_params[:toc_location], saved_location)
  end

  def toc_location_for_lesson(lesson)
    lesson.extend(ParallelLocationFinding).parallel_or_default_location(req_params[:toc_location])
  end

  def current_topic
    @current_topic ||= display_lesson.extend(ParallelLocationFinding).current_topic(req_params, saved_location)
  end

  def activity_list_header
    @activity_list_header ||= display_lesson.activity_list_header(current_topic)
  end

  def course_units_link
    if needs_course_units_link?
      #the :show_units_url_options is used for the 'show all lessons' link in the carousel
      #the :current_state_url_options is used for maintaining the current state of 'show all lessons' in the
      #carousel when switching lessons
      if req_params[:all_units] == 'true'
        @course_units_link ||= { :show_all_units_url_options => {:all_units => 'false'}, :current_state_url_options => {:all_units => 'true'},
                              :label => "Only show #{program.toc_unit_label}s for my course" }
      else
      path_options = req_params[:start_unit].present? ? {:start_unit => req_params[:start_unit], :all_units => 'true'} : {:all_units => 'true'}
      @course_units_link ||= { :label => "Show all #{program.toc_unit_label}s", :show_all_units_url_options => path_options,
                             :current_state_url_options => {:all_units => 'false'} }
      end
    else
      {}
    end
  end

  def can_edit_course_library?
    course_library_edit_policy.can_edit?
  end

  def can_edit_activity?(activity)
    course_library_edit_policy.can_edit_activity?(activity)
  end

  def can_remove_activity?(activity)
    current_user == current_focus.course.owner
  end

  private def course_library_edit_policy
    @course_library_edit_policy ||= CourseLibraryEditPolicy.new(current_user, current_focus)
  end

  def has_more_than_one_lesson?(unit)
    lessons_for(unit).size > 1
  end

  def text_for_lesson_link(unit, lesson)
    if !program.two_tier? || has_more_than_one_lesson?(unit) || has_one_lesson_with_same_name?(unit)
      lesson.name
    else
      "#{unit.name} | #{lesson.name}"
    end
  end

  def has_one_lesson_with_same_name?(unit)
    !has_more_than_one_lesson?(unit) && lessons_for(unit).first.name == unit.name
  end
  private :has_one_lesson_with_same_name?

  def units_min_rank
    units.map(&:rank).min
  end

  def units_max_rank
    units.map(&:rank).max
  end

  def visible_unit_ranks
    units.map(&:rank)
  end

  def units
    @units ||= if valid_sections.present?
                 valid_sections.first.units(req_params[:all_units])
               else
                 program.browsable_units
               end
  end

  private def valid_sections
    @valid_sections ||= sections && sections.reject(&:zero?)
  end

  def start_unit
    @start_unit ||= display_unit.rank
  end

  def lesson_classes(current_unit, current_lesson)
    current_lesson_classes = ''
    current_lesson_classes += display_unit?(current_unit) ? ' selected_unit_title_link' : ' unselected_unit_title_link'
    current_lesson_classes += display_lesson?(current_lesson) ? ' current_lesson' : ''
    current_lesson_classes
  end

  def current_lesson_label
    if activities.present? && activities.first.lesson
      activities.first.lesson.display_name
    else
      ''
    end
  end

  def units_and_lessons_partial
    if program.units.count == 2
      'partials/two_units_and_lessons'
    else
      'partials/units_and_lessons'
    end
  end

  def activity_in_course_library?(activity)
    visible_activities_ids.include? activity.id
  end

  def base_url_params
    { program_id: program.id }
  end

  def enterprise?
    return false if current_focus.course&.school.nil?

    current_focus.course&.school.enterprise_for_program?(program.id)
  end

  def saved_location
    @saved_location
  end
  private :saved_location

  def req_params
    @req_params || {}
  end
  private :req_params

  def needs_course_units_link?
    sections.present? && !course_covers_all_program_units?
  end
  private :needs_course_units_link?

  def course_covers_all_program_units?
    sections.first.covers_all_program_units?
  end
  private :course_covers_all_program_units?

  def selector_units
    units.map do |unit|
      icon_filename = if unit.media_item.nil?
                        ActionController::Base.helpers.asset_path('music/ui/transparent.png')
                      else
                        unit.media_item.public_filename
                      end
      more_than_one_lesson = has_more_than_one_lesson?(unit)
      UnitForSelector.new(more_than_one_lesson, unit.name, icon_filename, chinese_labels(unit),
                          selector_lessons(unit.lessons, unit.rank))
    end
  end
  private :selector_units

  def chinese_labels(unit)
    {
      display_name: unit.display_name,
      english_title: unit.english_title,
      chinese_title: unit.chinese_title,
      pinyin_title: unit.pinyin_title
    }
  end
  private :chinese_labels

  def selector_lessons(lessons, unit_rank)
    lessons.map do |lesson|
      path = lesson_path(lesson, unit_rank)
      selected_lesson = display_lesson?(lesson)
      LessonForSelector.new(lesson.name, path, selected_lesson)
    end
  end
  private :selector_lessons

  def lesson_path(lesson, unit_rank)
    base_url(all_units: req_params[:all_units], start_unit: unit_rank,
             display_lesson: lesson, toc_location: current_strand)
  end
  private :lesson_path

  def dropdown
    return @dropdown if defined?(@dropdown)
    label = course_units_link ? course_units_link[:label] : ''
    @dropdown = Selector.new(selector_units, unit_range_toggle_path, label)
  end

  def unit_range_toggle_path
    if course_units_link.present?
      base_url(course_units_link[:show_all_units_url_options]
                .merge(toc_location: current_strand,
                       start_unit: start_unit))
    else
      false
    end
  end
  private :unit_range_toggle_path
end

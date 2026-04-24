class AssignmentFilter < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :course, -> { unscope(where: :is_template) }, optional: true
  belongs_to :lesson, optional: true
  belongs_to :previous_section, class_name: 'Section', optional: true
  belongs_to :category, optional: true

  scope :by_course, ->(course) { where(course_id: course) }
  scope :by_user, ->(user) { where(user_id: user) }

  attr_reader :requested_nr_of_activities, :activities

  NR_OF_ACTIVITIES_INCREMENTS = 100

  def self.find_or_create(instructor, course, lessons)
    filter = by_course(course).by_user(instructor).first
    filter || create!(user: instructor, course: course, lesson: lessons.first)
  end

  def filter(activities, nr_of_activities = NR_OF_ACTIVITIES_INCREMENTS)
    @activities = activities.to_a

    return [] if @activities.empty?

    lesson_filter
    previous_section_filter
    component_filter
    activity_type_filter
    partner_chat_permissions_filter
    school_chat_support_filter
    grading_method_filter
    content_type_filter

    set_requested_number_of_activities(nr_of_activities)

    return @activities if @activities.count <= @requested_nr_of_activities

    flattened_sorted_grouped_activities(@activities).slice(0, @requested_nr_of_activities)
  end

  def activity_types
    activity_type.blank? ? [] : activity_type.split(',')
  end

  def displayable_selected_activity_type
    Activity.humanize_activity_type(activity_types.first)
  end

  def selected_content_type
    content_type.presence || 'Activities'
  end

  def has_more_displayable_activities?
    return false if @activities.count <= @requested_nr_of_activities

    true
  end

  def how_many_more_displayable_activities?
    return 0 if @activities.count <= @requested_nr_of_activities

    (@activities.count - @requested_nr_of_activities)
  end

  def total_number_of_activities
    @activities.count
  end

  def current_requested_number_of_activities
    @requested_nr_of_activities
  end

  def next_requested_nr_of_activities
    @requested_nr_of_activities + NR_OF_ACTIVITIES_INCREMENTS
  end

  def partner_chat_permissions_filter
    if course&.chat_disabled?
      @activities.reject!(&:partner_chat?)
    end
  end

  def school_chat_support_filter
    return unless course&.school&.has_chat_support_disabled?

    @activities.reject! do |activity|
      activity.partner_chat? || activity.group_chat?
    end
  end

  def activity_count_delta
    NR_OF_ACTIVITIES_INCREMENTS
  end

  def start_date
    previous_section ?  previous_section.course.start_date.to_date : Time.zone.now.to_date
  end

  def end_date
    # End date doesn't make sense unless we have a previous section, so just default to today's date.
    previous_section ?  previous_section.course.end_date.to_date : Time.zone.now.to_date
  end

  def group_by_lesson_plus_concept_and_sort(activities)
    grouped_activities_hash[activities]
  end

  private

  def set_requested_number_of_activities(nr_of_activities)
    return @requested_nr_of_activities = NR_OF_ACTIVITIES_INCREMENTS unless nr_of_activities
    @requested_nr_of_activities = nr_of_activities.to_i
  end

  def lesson_filter
    return unless lesson_id

    lesson = Lesson.find(lesson_id)
    @activities &= lesson.activities(sections: course&.sections, current_user: user)

    return unless toc_entry_location

    strand = lesson.strand_for_toc_location(toc_entry_location)
    if strand
      @activities &= strand.descendant_activities(
        sections: course&.sections,
        current_user: user
      )
    end
  end

  def previous_section_filter
    return unless previous_section

    @activities &= previous_section.activities
    @activities &= previous_section.activities_in_category(category) if category
    @activities &= previous_section.activities_in_week(week) if week.present?
    @activities &= previous_section.activities_on_day(day) if day
  end

  def component_filter
    @activities &= course.activities(user).where(component_name: component) if component.present?
  end

  def activity_type_filter
    @activities &= course.activities(user).where(activity_type: activity_types) if activity_types.any?
  end

  def grading_method_filter
    @activities &= course.activities(user).where(grading_method:) if grading_method.present?
  end

  def content_type_filter
    case content_type
    when nil, '', 'Activities'
      @activities = activities.reject(&:assessment?)
    when 'Assessment'
      @activities = activities.select(&:assessment?)
    end
  end

  def grouped_activities_hash
    @grouped_activities_hash ||= Hash.new do |hash, key|
      hash[key] = key.group_by do |act|
        "#{act.lesson_name} | #{act.concept_name}"
      end.map do |act|
        # convert from OrderedHash to Array, and sort each group
        [act[0], act[1].flatten.sort]
      end.sort do |a, b|
        # sort the groups based on the first element in the group
        a[1].first <=> b[1].first
      end
    end
  end

  def flattened_sorted_grouped_activities(activities)
    grouped_activities_hash[activities].map do |act|
      act[1]
    end.flatten
  end
end

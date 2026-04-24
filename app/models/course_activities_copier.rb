class CourseActivitiesCopier
  attr_accessor :from_course_id, :to_course_id, :shared_only, :activities_data_method
  def initialize(from_course_id, to_course_id, shared_only: false)
    self.from_course_id = from_course_id
    self.to_course_id = to_course_id
    self.shared_only = shared_only
    method_name = "#{'shared_' if shared_only}activities_data_for_library"
    self.activities_data_method = method(method_name.to_sym)
  end

  def copy
    if activities_for_library.present?
      ActiveRecord::Base.transaction do
        CourseLibraryActivity.import([:activity_id, :course_id, :hidden], activities_for_library)
      end
    end

    self
  end

  def activities_for_library
    @activities_for_library ||= activities_to_copy.map do |activity|
      [activity.activity_id, to_course_id, activity.hidden]
    end
  end
  private :activities_for_library

  def activities_to_copy
    from_course_activities.each_with_object([]) do |(_activity_id, activity), memo|
      memo << activity unless already_in_library?(activity.activity_id)
    end
  end
  private :activities_to_copy

  def already_in_library?(activity_id)
    to_course_activities[activity_id]
  end
  private :already_in_library?

  def from_course_activities
    @from_course_activities ||= activities_data_method.call(from_course_id)
  end
  private :from_course_activities

  def to_course_activities
    @to_course_activities ||= activities_data_for_library(to_course_id)
  end
  private :to_course_activities

  def activities_data_for_library(course_id)
    CourseLibraryActivity
      .by_course(course_id)
      .instructor_created
      .select('course_library_activities.activity_id, course_library_activities.hidden')
      .index_by(&:activity_id)
  end
  private :activities_data_for_library

  def shared_activities_data_for_library(course_id)
    # find all of the course library activities that also have an activity_id where
    # is_shared is true in the shared library activities table.
    CourseLibraryActivity
      .joins('INNER JOIN shared_library_activities ' \
             'ON shared_library_activities.activity_id = course_library_activities.activity_id ' \
             'AND shared_library_activities.is_shared = true')
      .by_course(course_id)
      .instructor_created
      .select('course_library_activities.activity_id, course_library_activities.hidden')
      .index_by(&:activity_id)
  end
  private :shared_activities_data_for_library
end

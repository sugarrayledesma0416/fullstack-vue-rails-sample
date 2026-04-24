class CourseLibraryActivity < ApplicationRecord
  belongs_to :activity
  belongs_to :course

  validates_presence_of :course_id
  validates_presence_of :activity_id

  scope :by_course, ->(course) { where(course_id: course) }
  scope :instructor_created, lambda {
    joins(:activity)
      .where(['activities.instructor_revision_id IS NOT NULL'])
  }

  def self.hide_activity(activity_ids, course_id)
    instructor = Course.find(course_id).owner
    activities = Activity.where(id: activity_ids)
    activities.each do |activity|
      create_hidden(activity, course_id, instructor)
    end
  end

  def self.unhide_activity(activity_ids, course_id)
    library_entries = where(activity_id: activity_ids, course_id: course_id).includes(:activity)
    library_entries.each do |library_entry|
      if library_entry.activity.instructor_created?
        library_entry.update(hidden: false) if library_entry.hidden?
      else
        library_entry.destroy
      end
    end
  end

  def self.create_hidden(activity, course_id, instructor)
    # If found or created we unassign
    library_entry = where(activity_id: activity, course_id: course_id).first
    if library_entry
      library_entry.update(hidden: true) unless library_entry.hidden?
    else
      create(activity_id: activity.id, course_id: course_id, hidden: true)
    end
    unassign_activity(activity, course_id, instructor)
  end
  private_class_method :create_hidden

  def self.unassign_activity(activity, course_id, instructor)
    ActivityAssignment.new(activity, instructor, program = nil, { course_id: course_id }).unassign
  end
  private_class_method :unassign_activity
end


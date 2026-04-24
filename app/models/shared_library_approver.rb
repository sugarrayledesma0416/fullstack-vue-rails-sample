class SharedLibraryApprover
  attr_accessor :allow_copy, :school_id, :source_activity_id, :user

  def initialize(attrs, user)
    self.allow_copy = attrs[:allow_copy]
    self.school_id = attrs[:school_id]
    self.source_activity_id = attrs[:activity_id]
    self.user = user
  end

  def approve
    library_entry.approve_shared_activity
    # Explicitly check for false value so that a nil value defaults to true.
    library_entry.approve_allow_copy unless allow_copy == false

    SharedLibraryActivity.assign_activity_copy_id_and_approver(
      source_activity_id,
      shared_activity.id,
      school_id,
      user.id
    )
    create_course_library_entries
  end

  def approved_activity_title
    source_activity.title.strip_tags.html_decode
  end

  private def library_entry
    @library_entry ||= SharedLibraryActivity.find_by(
     school_id: school_id, source_activity_id: source_activity_id
    )
  end

  private def source_activity
    @source_activity ||= InstructorCreatedActivity.find(source_activity_id)
  end

  private def shared_activity
    @shared_activity ||= copy_source_activity
  end

  private def copy_source_activity
    if source_activity.assessment?
      AssessmentCopier.new(source_activity_id, user.id).copy.created_activity
    else
      source_activity.copy_to_instructor(user.id)
    end
  end

  private def create_course_library_entries
    CourseLibraryActivity.transaction do
      course_library_course_ids.each do |course_id|
        CourseLibraryActivity.create!(
          activity_id: shared_activity.id,
          course_id: course_id,
          hidden: true
        )
      end
    end
  end

  private def course_library_course_ids
    Course.open.where(program_id: program_id, school_id: school_id).where(
      'source_template_id is not null'
    ).pluck(:id)
  end

  private def program_id
    source_activity.concept.program_id
  end
end

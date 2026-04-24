class ActivityCopier
  # TODO: Needs unit tests. Copy tests from AssessmentCopier.
  # TODO: Extract common AssessmentCopier logic into shared base class.
  attr_accessor :user_id, :activity_id, :errors, :created_activity, :course_id

  def initialize(activity_id, user_id, course_id)
    self.activity_id = activity_id
    self.course_id = course_id
    self.user_id = user_id
    self.errors = []
    self.created_activity ||= InstructorCreatedActivity.new
  end

  def copy
    validate

    if valid?
      self.created_activity.process_as_assessment = false
      self.created_activity.title = activity.title
      self.created_activity.toc_location = activity.toc_location
      self.created_activity.lesson = activity.lesson
      # Grab attribute icon value instead of using '.icon' getter method.
      self.created_activity.icon = activity[:icon]
      self.created_activity.has_rubric = activity.has_rubric
      # When copying a rubric activity, it should appear in the same
      # component and with the same rank as the activity being
      # copied from.
      if activity.has_rubric?
        created_activity.component_name = activity.component_name
        created_activity.concept_rank = activity.concept_rank
        created_activity.toc_location_rank = activity.toc_location_rank

        created_activity.custom_rubrics.build(
          course_id:,
          instructor_id: user_id,
          source_activity_id: activity_id,
          source_rubric_id: activity.content_object.rubric.cms_rubric_id,
          strand_id: activity.toc_location
        )
      end
      self.created_activity.concept_id = activity.concept_id
      self.created_activity.instructor_id = user_id
      self.created_activity.generated_content = activity.content
      self.created_activity.activity_type = activity.activity_type
      self.created_activity.minutes_to_complete = activity.minutes_to_complete || 30
      self.created_activity.assignment_group = activity.assignment_group
      self.created_activity.save
    end

    self
  end

  def messages
    if valid?
      'Activity copied successfully'
    else
      errors.join(', ')
    end
  end

  def message_type
    if valid?
      :notice
    else
      :error
    end
  end

  def activity
    @activity ||= Activity.find_by(id: activity_id)
  end

  def validate
    if activity
      errors << 'You may not make more than one copy' if activity_has_custom_rubric_created?
    else
      errors << 'Activity not found'
    end
  end

  def valid?
    errors.empty?
  end

  private def activity_has_custom_rubric_created?
    CustomRubric.exists?(
      source_activity_id: activity_id,
      course_id: course_id
    )
  end
end

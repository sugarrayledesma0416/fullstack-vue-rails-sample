class AssessmentCopier

  attr_accessor :user_id, :activity_id, :errors, :created_activity

  def initialize(activity_id, user_id)
    self.activity_id = activity_id
    self.user_id = user_id
    self.errors = []
    self.created_activity ||= InstructorCreatedActivity.new
  end

  def copy
    validate

    if valid?
      self.created_activity.process_as_assessment = true
      self.created_activity.title = "Copy of #{assessment.title}"
      self.created_activity.toc_location = assessment.toc_location
      self.created_activity.lesson = assessment.lesson
      self.created_activity.icon = assessment.icon
      self.created_activity.concept_id = assessment.concept_id
      self.created_activity.instructor_id = user_id
      self.created_activity.generated_content = assessment.content
      self.created_activity.activity_type = assessment.activity_type
      self.created_activity.minutes_to_complete = assessment.minutes_to_complete || 30
      self.created_activity.assignment_group = assessment.assignment_group
      self.created_activity.content_json = assessment.generate_content_json
      self.created_activity.save
    end

    self
  end

  def messages
    if valid?
      'Assessment copied successfully'
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

  def assessment
    @assessment ||= Activity.where(id: activity_id).first
  end

  def validate
    errors << 'Assessment not found' unless assessment
  end

  def valid?
    errors.empty?
  end
end


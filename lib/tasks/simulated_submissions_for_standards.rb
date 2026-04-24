class SimulatedSubmissionsForStandards
  attr_accessor :activity_id, :errors, :number_of_students, :section_id

  def initialize(activity_id:, number_of_students:, section_id:)
    self.activity_id = activity_id
    self.number_of_students = number_of_students
    self.section_id = section_id
    self.errors = ActiveModel::Errors.new(self)
  end

  def process
    validate_params

    if errors.empty?
      clear_standards_results
      (1..number_of_students).each do |num|
        create_attempt(num)
        generate_standards_results(num)
      end
    end

    errors.empty?
  end

  # rubocop:disable Style/IfUnlessModifier
  def validate_params
    unless valid_section?
      errors.add(
        :base,
        "Section ##{section_id} not found, is not open or is in the wrong program."
      )
    end

    unless valid_activity?
      errors.add(
        :base,
        "Activity ##{activity_id} not found or is not a Standards Test."
      )
    end

    (1..number_of_students).each do |num|
      unless valid_student?(num)
        errors.add(:base, "`#{username(num)}` not found.")
      end
    end
  end
  # rubocop:enable Style/IfUnlessModifier

  def valid_section?
    section&.open? && section.course.program_id == activity&.lesson&.program_id
  end

  def valid_activity?
    activity&.standards_test?
  end

  def valid_student?(num)
    student(num).present?
  end

  private def generate_standards_results(num)
    standards_results = {}

    sub_activities.each do |sub_activity|
      grading_type = sub_activity.instructor_graded? ? 'instructor' : 'auto'

      # loop through questions and award points
      sub_activity.questions.each do |question|
        standards_results[question.try(:question_guid)] = {
          question_label: question.label,
          points_earned: calculate_pe(question.points_possible, grading_type, num),
          points_possible: question.points_possible
        }
      end
    end

    create_standards_results(standards_results, student(num).id)
  end

  private def create_standards_results(results_hash, user_id)
    StandardsResults.create!(
      cms_activity_id: activity.cms_activity_id,
      results_data: results_hash,
      section_id: section.id,
      user_id: user_id
    )
  rescue StandardError => e
    errors.add(:base, e.message)
  end

  private def calculate_pe(points_possible, grading_type, num)
    if grading_type == 'auto'
      correctness(num) * points_possible
    else
      instructor_grade(num, points_possible)
    end
  end

  private def clear_standards_results
    StandardsResults.where(
      cms_activity_id: activity.cms_activity_id,
      section_id: section.id
    ).map(&:delete)
  end

  # Completed attempt, no submission so don't try to actively look at
  #   stored_responses or results.
  # Generated assuming we need to refer to it when building report views.
  private def create_attempt(num)
    clear_attempt(num)

    Attempt.create!(
      activity_id: activity.id,
      attempt_number: 1,
      cms_activity_id: activity.cms_activity_id,
      cms_revision_id: activity.cms_revision_id,
      section_id: section.id,
      scoring_ruleset: ScoringRuleset.default,
      status_code: 2,
      time_spent: rand(25..35).minutes.to_i,
      user_id: student(num).id
    )
  rescue StandardError => e
    errors.add(:base, e.message)
  end

  private def clear_attempt(num)
    Attempt.where(
      section_id: section.id,
      user_id: student(num).id,
      activity_id: activity.id,
      status_code: 2
    ).first&.delete
  end

  # the higher the overall grade, the more often this returns correct
  private def correctness(num)
    rand(1000) < overall_grade(num) ? 1 : 0
  end

  # get an instructor grade around their overall grade
  private def instructor_grade(num, points_possible)
    grade_factor = [rand((overall_grade(num) - 5)..(overall_grade(num) + 5)), 1000].min
    ((grade_factor / 1000.0) * points_possible).round(1)
  end

  # attempt to give some naturalness to the student's success
  private def overall_grade(num)
    @overall_grade ||= {}
    @overall_grade[num] ||= rand(550..1000)
  end

  private def student(num)
    @student ||= {}
    @student[num] ||= Student.find_by(username: username(num))
  end

  private def username(num)
    "vhl_#{num}_student"
  end

  private def section
    @section ||= Section.find(section_id)
  rescue StandardError => e
    errors.add(:base, e.message)
    nil
  end

  private def sub_activities
    @sub_activities ||= activity.content_object.activities
  end

  private def activity
    @activity ||= Activity.find(activity_id)
  rescue StandardError => e
    errors.add(:base, e.message)
    nil
  end
end

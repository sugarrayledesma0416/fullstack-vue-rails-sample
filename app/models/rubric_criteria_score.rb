class RubricCriteriaScore < ApplicationRecord
  belongs_to :attempt

  scope :by_attempts, ->(attempt_ids) { where(attempt_id: attempt_ids) }

  def self.submit(params)
    attempt = find_attempt(params)
    # To avoid saving malformed json we raise an error in case
    # there is no criteria score for the current student to grade
    unless criteria_for_attempt_exist?(attempt, params)
      raise StandardError, "Criteria score missing for student #{params[:student].id}"
    end

    criteria_scores_hash = params[:criteria][attempt.id.to_s].to_unsafe_hash
    rubric = attempt.revision_activity.rubric
    validate_criteria(criteria_scores_hash, rubric)
    validate_criteria_scores(criteria_scores_hash, rubric)

    where(
      attempt_id: attempt
    ).first_or_create.update(criteria_score_json: criteria_scores_hash.to_json)
  end

  def self.criteria_for_attempt_exist?(attempt, params)
    return false unless attempt

    params[:criteria][attempt.id.to_s]
  end

  def self.find_attempt(params)
    params[:attempt] ||
      Attempt.find_by_student_section_and_activity(params[:student],
                                                   params[:section],
                                                   params[:activity])
  end

  def scores
    JSON.parse(criteria_score_json)
  end

  def sum
    scores.values.map(&:to_i).reduce(:+)
  end

  def self.validate_criteria(criteria_scores_hash, rubric)
    validate_criteria_titles(criteria_scores_hash, rubric)
    validate_criteria_scores(criteria_scores_hash, rubric)
  end

  private_class_method def self.validate_criteria_scores(scores, rubric)
    rubric.criterias.each do |crit|
      max_msg = "Score exceeds max score of #{crit.max_score} for category '#{crit.title}'"
      raise StandardError, max_msg if scores[crit.title].to_f > crit.max_score
    end
  end

  private_class_method def self.validate_criteria_titles(scores, rubric)
    criteria_msg = 'Criteria titles do not match the rubric'
    raise StandardError, criteria_msg if rubric.criterias.map(&:title) != scores.keys
  end
end

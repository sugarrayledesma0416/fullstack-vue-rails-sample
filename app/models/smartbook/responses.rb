module Smartbook
  class Responses
    def initialize(answered_statements)
      @answered_statements = answered_statements
    end

    # only questions that the student answered;
    # filters out multiple attempts
    def answered
      @answered ||= select_latest_responses(all_answered)
    end

    # count of all answered questions including multiple attempts;
    # used to mitigate risk of a race condition
    def all_answered
      @all_answered ||= all_answered_responses
    end

    def answered_by_label
      @answered_by_label ||= answered.map { |response| [response.label, response] }.to_h
    end

    def auto_graded
      @auto_graded ||= answered.select(&:auto_graded?)
    end

    def auto_graded_by_label
      @auto_graded_by_label ||= auto_graded.group_by(&:label)
    end

    def latest_auto_graded_responses
      @latest_auto_graded_responses ||= auto_graded_by_label.values.map do |responses|
        responses.max_by(&:submission_time)
      end
    end

    # only answered questions that require instructor-grading
    def instructor_graded
      @instructor_graded ||= answered.select(&:instructor_gradable?)
    end

    def instructor_graded_by_label
      @instructor_graded_by_label ||= instructor_graded.group_by(&:label)
    end

    def latest_instructor_graded_responses
      @latest_instructor_graded_responses ||= instructor_graded_by_label.values.map do |responses|
        responses.max_by(&:submission_time)
      end
    end

    def points_earned(question_label)
      answered_by_label[question_label]&.points_earned || 0
    end

    # Convert statements into smartbook responses.
    private def all_answered_responses
      @answered_statements.map do |statement|
        if statement.verb == Xapi::VERB_ANSWERED
          Response.new(statement)
        end
      end.compact
    end

    # Also make sure we get the latest submitted one
    private def select_latest_responses(responses)
      # take the latest submission of any answered
      # responses for the same interaction;
      # always grab the sole attempt for an instructor_graded
      selected_attempts = responses.each_with_object({}) do |attempt, memo|
        # select it if it isn't there already
        memo[attempt.interaction_id] ||= attempt
        # check if there is a newer one
        if attempt.submission_time > memo[attempt.interaction_id].submission_time
          memo[attempt.interaction_id] = attempt
        end
      end
      selected_attempts.values.sort
    end
  end
end

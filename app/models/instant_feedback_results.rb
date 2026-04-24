class InstantFeedbackResults
  attr_accessor :activity, :attempt, :disable_enhanced_feedback, :inputs
  alias disable_enhanced_feedback? disable_enhanced_feedback

  def initialize(activity:, attempt:, disable_enhanced_feedback:, inputs:)
    self.activity = activity
    self.attempt = attempt
    self.disable_enhanced_feedback = disable_enhanced_feedback
    self.inputs = inputs
  end

  def payload
    results = content_object.validate_responses(combined_params, scoring_ruleset, :saved)
    # Temporarily disable until the re-try views are fixed for
    # all question types after saving.
    # store_results(results)

    inputs.each_with_object({}) do |input, memo|
      memo[input[:label]] = payload_for_input(input, results)
    end
  end

  private def best_answer(input)
    return {} unless content_object.respond_to?(:best_answer)

    {
      correct_answer: content_object.best_answer(
        input[:label], input[:response]
      )
    }
  end

  private def combined_params
    existing_responses.merge(response_params)
  end

  private def content_object
    @content_object ||= activity.content_object
  end

  private def enhanced_feedback(input)
    return {} unless content_object.respond_to?(:enhanced_feedback_items)
    return {} if disable_enhanced_feedback?

    {
      enhanced_feedback_items: content_object.enhanced_feedback_items(
        input[:label], input[:response], scoring_ruleset
      )
    }
  end

  private def existing_responses
    (attempt.respond_to?(:saved_responses) && attempt.saved_responses.presence) || stored_responses
  end

  private def find_or_create_scoring_ruleset
    if attempt.respond_to?(:scoring_ruleset)
      attempt.scoring_ruleset
    else
      ScoringRuleset.default
    end.tap do |memo|
      memo.chinese = true if activity.content_object.language == 'zh'
    end
  end

  private def payload_for_input(input, results)
    {
      correctness: results.correctness(input[:label])
    }.merge(
      best_answer(input)
    ).merge(
      enhanced_feedback(input)
    ).merge(
      sample_answer(input)
    )
  end

  private def response_params
    inputs.each_with_object({}) do |input, memo|
      memo[input[:label]] = input[:response]
    end
  end

  private def sample_answer(input)
    return {} unless content_object.respond_to?(:sample_answer)

    { sample_answer: content_object.sample_answer(input[:label]) }
  end

  private def scoring_ruleset
    @scoring_ruleset ||= find_or_create_scoring_ruleset
  end

  private def stored_responses
    if attempt.respond_to?(:stored_responses)
      attempt.stored_responses
    else
      {}
    end
  end

  private def store_results(results)
    return unless attempt.respond_to?(:results_datastore)

    attempt.results_datastore.write(results, AttemptSubmission::Mode::SAVED)
  end
end

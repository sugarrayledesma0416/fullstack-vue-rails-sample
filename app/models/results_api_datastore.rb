class ResultsApiDatastore
  include DataStorable

  def read
    _read(@attempt.saved_submission_id || @attempt.submission_id)
  end

  def write(results, save_mode = AttemptSubmission::Mode::SUBMITTED)
    response = SubmissionClient::Submission.create(attempt_id: @attempt.id,
                                                   partition_key: @attempt.submission_partition_key,
                                                   data: results_payload(results))

    @attempt.set_submission(0, 0, response.id, save_mode)
    response.id
  end

  # Returns responses stored in the process, but not saved as final yet
  def stored_responses
    _read(@attempt.submission_id)
  end

  # Returns saved as final responses
  def saved_responses
    _read(@attempt.saved_submission_id)
  end

  # this can be moved to the results class in MAE
  def results_payload(results)
    return results.to_json if results.is_a?(Hash)
    if results.respond_to?(:each)
      responses = {}
      results.each do |result|
        responses[result[:label]] = result[:response]
      end
      responses.to_json
    else
      fail 'Unsupported Data format.'
    end
  end
  private :results_payload

  def _read(s_id)
    submissions = SubmissionClient::Submission.find(s_id, @attempt.submission_partition_key)
    submissions.any? ? submissions.first.response['data'] : {}
  rescue StandardError => e
    VHLMonitor.notify(e, error_message: "Attempt id #{@attempt.id} S-id #{s_id}"\
                                      " Pkey #{@attempt.submission_partition_key}")
    {}
  end
  private :_read

  class MultipleAttempts
    attr_reader :attempts
    def initialize(attempts)
      @attempts = attempts
    end

    def cacheable?
      # check only stored responses
      # If attempts is an ActiveRecord::Relation or similar,
      # count call issues a sql-query, which is not intended.
      attempts.size == attempts.to_a.count(&:submission_id)
    end

    def stored_response(attempt)
      unless defined?(@cache)
        submissions = SubmissionClient::Submission.find(attempts.map(&:submission_id),
                                                        attempts.map(&:submission_partition_key))

        @cache = submissions.each_with_object({}) do |submission, memo|
          memo[submission.attempt_id] = submission
        end
      end
      @cache[attempt.id].data
    end
  end
end

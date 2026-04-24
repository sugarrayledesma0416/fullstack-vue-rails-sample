module AttemptStats
  def validate_responses(activity, submitted_values, request_env, mode = :submitted)
    raise "Can't validate responses for santillana activities" if activity.santillana?

    @form_id = submitted_values[:form_id]  # for stats payload
    submitted_keys = submitted_values.keys.map(&:to_s)
    missing_keys = expected_keys - submitted_keys

    send_logstash_data(missing_keys, expected_keys, :validate_responses, mode, request_env)

    super
  end

  def stored_responses
    responses = super
    # smartbook activities use attempts to save the content of the statements
    # received by the host. Since we don't have any expected keys, we just
    # return the responses.
    return responses if activity.activity_type == 'smart_book'

    # check keys if we have a full set of responses
    missing_keys = expected_keys - responses.keys
    send_logstash_data(missing_keys, expected_keys, :stored_responses)

    responses
  end

  private def expected_keys
    if activity.smart_book?
      smartbook_responses.instructor_graded
    else
      activity.result_labels
    end
  end

  def missing_keys_stats(keys)
    keys.each_with_object({}) do |key, memo|
      memo[key.activity_type] ||= []
      memo[key.activity_type] << key
    end
  end

  def send_logstash_data(missing_keys, expected_keys, source, mode = nil, request_env = {})
    percent_missing = ((missing_keys.size.to_f/expected_keys.size) * 100).round(1)
    percent_missing = percent_missing.nan? ? 0.0 : percent_missing
    mode = practice? ? :practice : (mode || :review)

    payload = {'type' => 'logstash_object',
                vhl_component: 'missing_submission_keys',
                missing_keys_detail: missing_keys_stats(missing_keys),
                percent_keys_missing: percent_missing,
                all_keys_missing: percent_missing == 100.0,
                data_source: source,
                activity_id: activity_id,
                activity_type: activity.activity_type,
                user_id: user_id,
                status: status_code,
                mode: mode,
                attempt_number: attempt_number,
                section_id: section_id,
                form_id: @form_id || '',
                navigator_user_agent: request_env['HTTP_USER_AGENT'],
                application: :m3,
                environment: Rails.env}
    STATS_PROXY.relay(payload)
    Rails.logger.debug("MISSING_KEYS: #{payload}") if Rails.env.development?
  end
end

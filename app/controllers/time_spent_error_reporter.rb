
class TimeSpentErrorReporter
  EARLIEST_POSSIBLE_START_TIME = Time.parse('May 1, 2012').to_i 

  def initialize(start_time, end_time, request)
    @start_time = start_time
    @end_time = end_time
    @delta = end_time.to_i - start_time.to_i
    @request = request
  end

  def evaluate_and_log_error_cases  # log entry.
    error = delta_invalid
    if error
      GeneralLog.create(:log_type => error.to_s,
                        :data_format => 'json',
                        :data => time_spent_error_message)
    end
  end

  def times_contains_non_digits?
    [ @start_time, @end_time ].any?{ |target_time| target_time.to_s =~ /\D/ }
  end
  private :times_contains_non_digits?
  
  def start_time_blank?
    @start_time.to_i == 0
  end
  private :start_time_blank?
  
  def start_time_precedes_earliest_possible?
    @start_time.to_i < EARLIEST_POSSIBLE_START_TIME
  end
  private :start_time_precedes_earliest_possible?

  def delta_exceeds_max_possible?
    @delta > Attempt::MAX_POSSIBLE_TIME_DELTA
  end
  private :delta_exceeds_max_possible?


  def delta_invalid
    case 
    when times_contains_non_digits?
      ActivityTimeContainsNonDigit
    when start_time_blank?
      ActivityStartTimeBlank
    when start_time_precedes_earliest_possible?
      ActivityStartTimeTooLow
    when delta_exceeds_max_possible?
      ActivityTimeSpentTooHigh
    else
      false
    end
  end
  private :delta_invalid

  def time_spent_error_message
    time_data = { :start_time => @start_time, :end_time => @end_time }
    session_data = @request.session
    path_parameters = @request.path_parameters
    query_parameters = @request.query_parameters
    request_uri = @request.fullpath
    remote_ip = @request.remote_ip
    cookies_hash = @request.cookies
    header_data = @request.headers
    environment_data = header_info_to_log.inject({}) { |hash, header_key| hash[header_key] = header_data[header_key.to_s]; hash }
    message_hash = { :time_data => time_data, :session_data => session_data, 
                     :path_parameters => path_parameters, :query_parameters => query_parameters, 
                     :request_uri => request_uri, :remote_ip => remote_ip, 
                     :cookies_hash => cookies_hash, :environment_data => environment_data }
    message_hash.to_json
  end
  private :time_spent_error_message

  def header_info_to_log
    [ :HTTP_REFERER, :HTTP_USER_AGENT, :REQUEST_URI, :REQUEST_METHOD ]
  end
  private :header_info_to_log
end

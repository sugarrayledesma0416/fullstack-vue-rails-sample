FactoryBot.define do
  sequence :activity_states do |n|
    states = ['try', 're-try', 'review', 'decide']
    states[n % states.length]
  end

  factory :help_request do
    association :user, factory: :student
    program
    activity
    section
    request_type { 'request_help' }
    helpable_item_type { 'direction_line' }
    helpable_item_id { 'dl' }
    cms_activity_id { 1 }
    activity_state { generate(:activity_states) }
    cms_revision_id { 10 }
    http_referer { 'www.example.com' }
    ip_address { '127.0.0.1' }
    user_agent_string do
      'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; WOW64; ' \
      'Trident/4.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; Media ' \
      'Center PC 6.0; .NET4.0C)'
    end
    browser_name { 'Mozilla/4.0' }
    browser_version { '4.0' }
    operating_system { 'Windows NT 6.1' }
    flash_version { '11.0.0.3' }
    request_params { 'some_request_params' }
    student_comment { 'student comment' }
    instructor_comment { 'instructor comment' }
  end

  factory :review_request, parent: :help_request do
    request_type { 'request_review' }
  end

  factory :technical_problem_report, parent: :help_request do
    request_type { 'report_technical_problem' }
  end

  factory :content_problem_report, parent: :help_request do
    request_type { 'report_content_problem' }
  end

  factory :server_error_report do
    user
    error_id { 1 }
    http_referer { 'vhlcentral.com/url/test' }
    ip_address { '192.168.1.17' }
    user_agent_string { 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; WOW64; Trident/4.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; Media Center PC 6.0; .NET4.0C)' }
    browser_name { 'Mozilla/4.0' }
    browser_version { '4.0' }
    operating_system { 'Windows NT 6.1' }
  end
end

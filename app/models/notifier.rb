class Notifier < ActionMailer::Base
  default :from => '"Vista Higher Learning" <no_reply@vistahigherlearning.com>'

  def scheduled_task_status(task_name, message)
    @task_name = task_name
    @message   = message

    mail(:to => "adam@vistahigherlearning.com, aparadise@vistahigherlearning.com",
         :subject => "Status notification for scheduled task '#{task_name}'",
         :date => Time.zone.now)
  end

  def problem_report(help_request)
    problem_type = ( help_request.technical_problem? ? 'technical problem' : 'content problem' )
    @help_request = help_request
    mail( :from => '"M3 Problem Reports" <no_reply_problem_reports@vistahigherlearning.com>',
          :subject => "A #{problem_type} has been reported by a user.#{env_suffix}",
          :to => problem_report_recipients,
          :date => Time.zone.now)
  end

  def server_error_report(server_error)
    @server_error = server_error
    mail( :from => '"VHLMonitor Problem Reports" <no_reply_problem_reports@vistahigherlearning.com>',
          :subject => "A rollbar issue has been reported by a user.#{env_suffix}",
          :to => 'qa@vistahigherlearning.com',
          :date => Time.zone.now)
  end

  private

  def problem_report_recipients
    if Rails.env.live?
      'ts@vistahigherlearning.com'
    else
      'qa@vistahigherlearning.com'
    end
  end
  private :problem_report_recipients

  def recipients_list_from_grade_offset(grade_offsets)
    grade_offsets.collect(&:section).collect(&:instructors).flatten.collect{ |user|
      "\"#{user.first_name} #{user.last_name}\" <#{user.email}>"
    }.join(', ')
  end

  def self.host_live?(host)
    ! host.grep(/:live$/).empty?
  end

  def env_suffix
    if Rails.env.live?
      ''
    else
      " (From qa server: #{Rails.env})" # So support knows when we're sending from qa servers.
    end
  end
  private :env_suffix
end

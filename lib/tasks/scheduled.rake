
namespace :scheduled do
  desc "Runs a pre-defined task specified as an argument"
  task :run => :environment do
    begin
      require 'lib/session_cleanup'

      tasks = ['session_cleanup', 'error_test']

      task_name = ENV['task']
      raise "No task name specified. USAGE: rake scheduled:run task=<#{tasks.join('|')}>" unless task_name
      raise "Task does not exist. Possible tasks: #{tasks.join('|')}" unless tasks.include? task_name

      case task_name
      when 'session_cleanup' then SessionCleanup.cleanup
      when 'error_test' then raise "This error should be sent to hoptoad and emailed"
      end

    rescue => e
      e.message << "\nSpecified task: '#{task_name}'"
      HoptoadNotifier.notify(e)
      send_email_notification(task_name, e.message)
      raise(e)
    end
  end

end


def send_email_notification(task_name, message)
  Notifier.deliver_scheduled_task_status(task_name, message)
end

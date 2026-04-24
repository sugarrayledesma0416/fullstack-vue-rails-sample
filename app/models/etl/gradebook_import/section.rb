module Etl
  module GradebookImport
    class Section < Base
      def model_attr_names
        %w(id course_id days_to_show_assignment_due_date name school_id) + common_fields
      end

      def special_attribute_handling
        @current_record.time_zone = convert_to_standard_time_zone(@new_attrs['time_zone'])
        # coming from SQS it will be a string, coming directly from M3 will be a Time object;
        # want to handle it the same so ensure it is a String before parsing it
        due_time = Time.parse(@new_attrs['due_time'].to_s)
        # Convert number of seconds into time string.
        seconds = due_time.seconds_since_midnight
        @current_record.due_time = Time.at(seconds).utc.strftime('%H:%M:%S')
      end

      private def convert_to_standard_time_zone(time_zone)
        zone = ActiveSupport::TimeZone[time_zone]
        zone.tzinfo.name
      end
    end
  end
end

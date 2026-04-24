module Etl
  module GradebookImport
    module DueDateConversion
      # Returns a hash containing values for day_id and week_id, based on the
      # given due date. In the gradebook assignment and individual assignment
      # models, day_id is the equivalent of due_date, and week_id is the
      # first day (Sunday) of the week containing the due date.
      def convert_due_date(due_date)
        day_id = week_id = nil

        if due_date.present?
          # due_date gets transformed to day_id, week_id
          # coming from SQS it will be a string, coming directly from M3 will be a Time object;
          # want to handle it the same to ensure it is a String before parsing it
          day_id = Time.parse(@new_attrs['due_date'].to_s)
          week_id = ::Week.week_containing(@new_attrs['due_date'])
        end

        {
          day_id: day_id,
          week_id: week_id
        }
      end
    end
  end
end

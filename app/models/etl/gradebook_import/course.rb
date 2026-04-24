module Etl
  module GradebookImport
    class Course < Base
      def model_attr_names
        %w(id current_events_unit_id first_unit_id end_date last_unit_id name start_date school_id) + common_fields
      end
    end
  end
end

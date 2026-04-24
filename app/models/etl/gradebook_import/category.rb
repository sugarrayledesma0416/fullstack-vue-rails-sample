module Etl
  module GradebookImport
    class Category < Base
      def model_attr_names
        %w( id accept_late_work course_id name school_id weighting_percent) + common_fields
      end

      def special_attribute_handling
        @current_record.set_details_from_attrs(@new_attrs)
      end
    end
  end
end

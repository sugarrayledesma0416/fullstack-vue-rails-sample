module Etl
  module GradebookImport
    class IndividualAssignment < Base
      include DueDateConversion

      def model_attr_names
        %w[
          activity_id
          section_id
          user_id
        ] + common_fields
      end

      def find_existing
        @model_type.where(
          activity_id: @new_attrs['activity_id'],
          section_id: @new_attrs['section_id'],
          user_id: @new_attrs['user_id']
        ).first
      end

      def special_attribute_handling
        results = convert_due_date(@new_attrs['due_date'])
        @current_record.day_id = results[:day_id]
        @current_record.week_id = results[:week_id]
      end
    end
  end
end

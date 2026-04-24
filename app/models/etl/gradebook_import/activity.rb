module Etl
  module GradebookImport
    class Activity < Base
      def model_attr_names
        %w(id grading_method lesson_id points_possible student_title) + common_fields
      end

      def special_attribute_handling
        # strip line breaks and HTML tags
        @current_record.name = sanitize(@new_attrs['title'])
        @current_record.rank = @new_attrs['concept_rank']
        @current_record.gradeable = @new_attrs['submittable']
        @current_record.strand_id = @new_attrs['concept_id']
      end
    end
  end
end

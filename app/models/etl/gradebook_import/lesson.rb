module Etl
  module GradebookImport
    class Lesson < Base
      def model_attr_names
        %w(id rank program_id unit_id unit_rank) + common_fields
      end

      def special_attribute_handling
        # strip line breaks and HTML tags
        display_name = @new_attrs['label'].present? && @new_attrs['label'] || @new_attrs['name']
        @current_record.name = sanitize(display_name)
      end

    end
  end
end

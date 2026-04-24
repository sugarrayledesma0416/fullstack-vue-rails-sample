module Etl
  module GradebookImport
    class Strand < Base
      def model_attr_names
        %w(id rank assessment) + common_fields
      end

      def special_attribute_handling
        # strip line breaks and HTML tags
        @current_record.name = sanitize(@new_attrs['name'])
        @current_record.color = @new_attrs['background_color']
      end
    end
  end
end

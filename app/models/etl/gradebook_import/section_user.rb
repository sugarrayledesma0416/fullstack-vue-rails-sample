module Etl
  module GradebookImport
    class SectionUser < Base
      def model_attr_names
        %w(school_id section_id user_id) + common_fields
      end

      def find_existing
        @model_type.where(section_id: @new_attrs['section_id'], user_id: @new_attrs['user_id']).first
      end
    end
  end
end

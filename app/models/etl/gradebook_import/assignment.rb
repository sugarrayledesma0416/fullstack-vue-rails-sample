module Etl
  module GradebookImport
    class Assignment < Base
      include DueDateConversion

      def model_attr_names
        %w[
          category_id
          individually_assignable
          lesson_id
          school_id
          section_id
          strand_id
        ] + common_fields
      end

      def find_existing
        @model_type.where(section_id: @new_attrs['section_id'], activity_id: @new_attrs['assignable_id']).first
      end

      def special_attribute_handling
        @current_record.activity_id = @new_attrs['assignable_id']

        results = convert_due_date(@new_attrs['due_date'])
        @current_record.day_id = results[:day_id]
        @current_record.week_id = results[:week_id]

        @current_record.strand_id = @new_attrs['concept_id']
        # optional value
        @current_record.details = {}.tap do |details|
          details[:custom_due_time] =
            Time.parse(@new_attrs['custom_due_time'].to_s).strftime("%H:%M:%S") if @new_attrs['custom_due_time'].present?
        end
      end

      def handle_record_deletion
        @new_attrs['activity_id'] = @new_attrs['assignable_id']
        super
      end
    end
  end
end

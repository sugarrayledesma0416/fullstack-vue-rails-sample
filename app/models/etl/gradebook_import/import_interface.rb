module Etl
  module GradebookImport
    class ImportInterface
      def initialize(model_type, model_action)
        @model_type = model_type
        @model_action = model_action
      end

      def build_gradebook_object(new_attrs)
        model_name = @model_type.to_s.split('::').last
        @gb_import_model = "Etl::GradebookImport::#{model_name}".constantize.new(@model_type, @model_action, new_attrs)
        # if the record is deleted, the following method will return nil
        # which is a signal to the ETL to halt processing of this record
        @gb_import_model.get_or_delete_record
      end
    end
  end
end

module Etl
  module GradebookImport
    module Common
      class ImportTransform
        include SqsClientReader

        def process(record)
          gb_importer = ImportInterface.new(@gb_model_type, @gb_model_action)
          gb_object = gb_importer.build_gradebook_object(record)
          log_etl_info('queue-msg-deletion', @receipt_handle, @gb_model_type.name)
          # remove the message from the queue only after
          # it is successfully processed
          delete_message(@receipt_handle)
          gb_object
        end
      end
    end
  end
end

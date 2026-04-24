module Etl
  module GradebookImport
    module MessageEtl
      def setup(num_messages)
        Kiba.parse do
          source Common::ImportSource, num_messages
          transform Common::MessageTransform
          destination Common::GradebookDestination
        end
      end

      module_function :setup

      class MessageTransform < Common::ImportTransform
        def process(record)
          # look at message attributes, process by specified action and model type
          model_name = record.message_attributes['M3_Model'][:string_value]
          @gb_model_action = record.message_attributes['action'][:string_value]
          log_etl_info(
            'dequeue',
            "#{record.receipt_handle}:#{record.body}",
            "#{model_name}:#{@gb_model_action}"
          )
          # store receipt handle so the message can be deleted
          # after successful processing
          @receipt_handle = record.receipt_handle
          model_attributes = JSON.parse(record.body)
          # convert certain M3 models to GradeBook models after extracting the attributes
          @gb_model_type =
            case model_name
            when 'Enrollment' then GradebookEngine::SectionUser
            when 'Concept' then GradebookEngine::Strand
            else "GradebookEngine::#{model_name}".constantize
            end
          super(model_attributes)
        end
      end
    end
  end
end

module Etl
  module GradebookImport
    module Common
      class ImportSource
        include SqsClientReader
        def initialize(num_messages)
          # how many messages to read from the queue in a batch
          super(num_messages)
          @records = receive_messages
        end

        def each
          @records.each do |record|
            yield record
          end
        end
      end
    end
  end
end

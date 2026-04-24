module Etl
  module GradebookImport
    module Common
      class GradebookDestination
        include EtlLogger
        def initialize; end

        def write(record)
          record.save
        rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid => e
          log_etl_error(
            'database-write-error',
            e,
            record.attributes,
            record.class.name
          )
        end

        def close; end
      end
    end
  end
end

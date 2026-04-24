module Etl
  module GradebookImport
    class User < Base
      def model_attr_names
        %w(id first_name last_name fake guid) + common_fields
      end
    end
  end
end

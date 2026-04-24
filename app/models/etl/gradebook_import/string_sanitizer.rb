module Etl
  module GradebookImport
    module StringSanitizer
      def sanitize(string_with_tags)
        # replace line breaks with spaces
        # and remove any other html tags
        ActionController::Base.helpers.strip_tags(string_with_tags.gsub('<br />', ' '))
      end
    end
  end
end
module Cartridge
  module Converters
    module TitleSanitizer
      def sanitize_title(title)
        title.strip_tags.strip.squeeze(' ')
      end
    end
  end
end

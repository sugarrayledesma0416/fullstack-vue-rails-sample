require 'multi_version_common_cartridge'

module Cartridge
  module Converters
    class LessonConverter
      include TitleSanitizer

      def initialize(lesson)
        @lesson = lesson
      end

      def convert
        MultiVersionCommonCartridge::Item.new.tap do |item|
          item.title = sanitize_title(@lesson.name)
          item.identifier = '_' + SecureRandom.uuid
          item.children = toc_entry_items
        end
      end

      private def toc_entry_items
        @lesson.strands.map do |toc_entry|
          TocEntryConverter.new(toc_entry).convert
        end
      end
    end
  end
end

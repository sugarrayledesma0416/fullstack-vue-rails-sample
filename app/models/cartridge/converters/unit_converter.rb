require 'multi_version_common_cartridge'

module Cartridge
  module Converters
    class UnitConverter
      include TitleSanitizer

      def initialize(unit)
        @unit = unit
      end

      def convert
        MultiVersionCommonCartridge::Item.new.tap do |item|
          item.title = sanitize_title(@unit.name)
          item.identifier = '_' + SecureRandom.uuid
          item.children = lesson_items
        end
      end

      private def lesson_items
        @unit.lessons.map do |lesson|
          LessonConverter.new(lesson).convert
        end
      end
    end
  end
end

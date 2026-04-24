require 'multi_version_common_cartridge'

module Cartridge
  module Converters
    class ProgramConverter
      include TitleSanitizer

      NEWS_AND_CULTURA_UNIT_NAME = 'News and Cultural Updates'.freeze

      def initialize(program)
        @program = program
      end

      def convert
        MultiVersionCommonCartridge::Cartridge.new.tap do |cartridge|
          cartridge.manifest.set_title(sanitize_title(@program.title))
          cartridge.manifest.identifier = '_' + SecureRandom.uuid
          cartridge.manifest.organization_identifier = 'VHL_' + SecureRandom.uuid

          cartridge.items = unit_or_lesson_items + vtext_item + [resource_items]
        end
      end

      private def unit_or_lesson_items
        if @program.two_tier?
          @program.visible_units_and_resource_units
                  .where.not(name: NEWS_AND_CULTURA_UNIT_NAME).map do |unit|
            UnitConverter.new(unit).convert
          end
        else
          @program.visible_lessons
                  .reject { |lesson| lesson.unit.name == NEWS_AND_CULTURA_UNIT_NAME }
                  .map do |lesson|
            LessonConverter.new(lesson).convert
          end
        end
      end

      private def vtext_item
        vtext_item = VtextConverter.new(@program).convert
        vtext_item ? [vtext_item] : []
      end

      private def resource_items
        MultiVersionCommonCartridge::Item.new.tap do |item|
          item.title = 'resources'
          item.identifier = '_' + SecureRandom.uuid
          item.children = resources.map do |resource|
            ResourceConverter.new(resource).convert
          end
        end
      end

      private def resources
        resources_scope.sorted_by_unit_rank.sorted_by_lesson.by_program @program
      end

      private def resources_scope
        Resource.unprotected
                .where(owner_id: nil)
                .where(source: 'VHL')
      end
    end
  end
end

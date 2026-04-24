require 'multi_version_common_cartridge'

module Cartridge
  module Converters
    class VtextConverter
      def initialize(program)
        @program = program
      end

      def convert
        return nil unless program_settings.has_vtext_link? \
                         || program_settings.has_teacher_vtext_link?

        vtext_cartridge_items = [].tap do |items|
          if program_settings.has_vtext_link?
            items << CartridgeItem.new(student_vtext_label, :student_vtext, @program).convert
          end
          if program_settings.has_teacher_vtext_link?
            items << CartridgeItem.new(instructor_vtext_label, :instructor_vtext, @program).convert
          end
        end
        MultiVersionCommonCartridge::Item.new.tap do |item|
          item.title = 'vtexts'
          item.identifier = '_' + SecureRandom.uuid
          item.children = vtext_cartridge_items
        end
      end

      private def program_settings
        @program_settings ||= ProgramSettings.new(@program)
      end

      private def student_vtext_label
        if program_settings.vtext_label.blank?
          'eCompanion'
        else
          program_settings.vtext_label
        end
      end

      private def instructor_vtext_label
        if program_settings.teacher_vtext_label.blank?
          @program.vista_online_learning? ? "Instructor's Manual" : "Teacher's Edition"
        else
          program_settings.teacher_vtext_label
        end
      end

      class CartridgeItem
        include TitleSanitizer
        include Exportable

        def initialize(label, resource_type, program)
          @label = label
          @resource_type = resource_type
          @program = program
        end

        def convert
          MultiVersionCommonCartridge::Item.new.tap do |item|
            item.title = sanitize_title(@label)
            item.identifier = '_' + SecureRandom.uuid
            item.resource = MultiVersionCommonCartridge::Resources::BasicLtiLink::BasicLtiLink.new.tap do |lti|
              lti.title = item.title
              lti.identifier = item.identifier + '_r'
              lti.description = ''
              lti.secure_launch_url = secure_launch_url

              lti.vendor.code = VENDOR_CODE
              lti.vendor.name = VENDOR_NAME
              lti.vendor.url = VENDOR_URL
              lti.vendor.contact_email = VENDOR_EMAIL

              lti.extensions << canvas_extension
            end
          end
        end

        private def resource_link
          @resource_link ||= Cartridge::ResourceLink.find_or_create(
            @program.id, @resource_type, @program
          )
        end
      end
    end
  end
end

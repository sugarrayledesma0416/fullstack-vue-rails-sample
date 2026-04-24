require 'tasks/demo_data/cleaner'
require 'tasks/demo_data/fixture'
require 'tasks/demo_data/program_content'

module DemoData
  class Loader
    include ProgramContent

    def load_base_data
      load_program_specific_data
      load_file_types_data
      DemoData::Fixture.load('countries')
      load_tech_support_data
    end

    def load_from_backup?
      return false
    end

    def load_program_specific_data
      return if load_from_backup?
      DemoData::Fixture.load('media_items')
      create_program_media_items
    end

    def load_tech_support_data
      DemoData::Fixture.load('help_entries')
      FactoryBot.create(:chat_enable_setting)
      populate_placeholder_help_entries
    end

    def load_content
      # book 50 and 2 tier programs are usually not needed
      # to load them, use load_fake_program_content instead
    end

    def load_fake_program_content
      return if load_from_backup?
      load_tables_of_contents
      load_activities

      # verified working, but skip for now... use only placeholder activities that have no media
      #ExampleData.create_activity_media unless defined?(OUT_OF_NETWORK)

      create_content_for_program_with_units_and_lessons
    end

    def load_tables_of_contents
      return if load_from_backup?
      DemoData::Fixture.load('units')
      DemoData::Fixture.load('lessons')
      load_lesson_toc_entries
      DemoData::Fixture.load('concepts')
    end

    def load_activities
      return if load_from_backup?
      DemoData::Cleaner.new.delete_all_activity_xml_files

      DemoData::Fixture.load('activities')
      import_activity_completion_times
      build_placeholder_activities
    end

    def load_file_types_data
      DemoData::Fixture.load('file_types')
    end

    private

    def populate_placeholder_help_entries
      puts "populating placeholder help entries"

      pages_with_help = HelpEntry.all.map(&:page).compact.uniq

      pages_to_create = HelpEntry.pages_that_can_have_help - pages_with_help
      pages_to_create.each do |page|
        FactoryBot.create(:help_entry, :page => page, :url => 'http://support.vhlcentral.com/?not_yet_defined')
      end
    end
  end
end

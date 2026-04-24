require_relative 'demo_data/cleaner'
require_relative 'demo_data/generator'
require_relative 'demo_data/loader'

namespace :demo_data do
  desc "Loads base (non-content) data for Maestro 3 app"
  task :load_base_data => :environment do
    DemoData::Loader.new.load_base_data
  end

  desc "Loads content data"
  task :load_content => :environment do
    DemoData::Loader.new.load_content
  end

  desc "Cleans up content data for Vistas4e program - run after publish from cms"
  task :clean_up_real_program => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Loader.new.update_program_data(ENV['program_id'])

    cleaner = DemoData::Cleaner.new
    cleaner.delete_all_resources

    generator = DemoData::Generator.new
    generator.create_resources(ENV['program_id'])
    generator.generate_video_thumbnails(ENV['program_id'])
  end

  desc "Create a new study plan practice test activity"
  task :generate_study_plan => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_study_plan_activity(ENV['program_id'])
  end

  desc "Create a thumbnail to the video activities"
  task :generate_video_thumbnails => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    generator = DemoData::Generator.new
    generator.generate_video_thumbnails(ENV['program_id'])
  end

  desc "Create a cumulative matching activity and link it into a program"
  task :generate_cumulative_matching_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_cumulative_matching_activity(ENV['program_id'])
  end

  desc "Create a video virtual chat activity and link it into a program"
  task generate_video_virtual_chat_activity: :environment do |task_name|
    if ENV['program_id'].blank? || ENV['poster_format'].blank?
      puts "usage: rake #{task_name} program_id=<id> poster_format=[png|jpg]"
      exit(1)
    end

    if ['png', 'jpg'].include? ENV['poster_format']
      DemoData::Generator.new.create_video_virtual_chat_activity(ENV['program_id'], ENV['poster_format'])
    else
      puts "poster format should be png or jpg."
      exit(1)
    end
  end

  desc 'Create a new HTML5 Vocab Tutorial Activity'
  task generate_vocab_tutorial_html5_activity: :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit 1
    end

    DemoData::Generator.new.create_tutorial_vocab_html5_activity(ENV['program_id'])
  end

  desc "Create a video virtual chat activity with gender and link it into a program"
  task generate_video_virtual_chat_activity_with_gender: :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_video_virtual_chat_activity_with_gender(ENV['program_id'])
  end

  desc "Create a learning engine diagnostic activity and link it into a program"
  task :generate_learning_engine_diagnostic_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_learning_engine_diagnostic_activity(ENV['program_id'])
  end

  desc "Create a learning engine interactive vocabulary chart activity and link it into a program"
  task :generate_learning_engine_interactive_vocab_chart_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_learning_engine_interactive_vocab_chart_activity(ENV['program_id'])
  end

  desc "Create a learning engine record and compare activity and link it into a program"
  task :generate_learning_engine_record_and_compare_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_learning_engine_record_and_compare_activity(ENV['program_id'])
  end

  desc "Create a pronunciation explore activity and link it into a program"
  task :generate_pronunciation_explore_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_pronunciation_explore_activity(ENV['program_id'])
  end

  desc "Create a pronunciation explore alphabet activity and link it into a program"
  task :generate_pronunciation_explore_alphabet_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_pronunciation_explore_alphabet_activity(ENV['program_id'])
  end

  desc "Create a interactive map activity and link it into a program"
  task :generate_interactive_map_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_interactive_map_activity(ENV['program_id'])
  end

  desc "Create a true false enhanced activity and link it into a program"
  task :generate_true_false_enhanced_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_true_false_enhanced_activity(ENV['program_id'])
  end

  desc "Create a geography reading activity and link it into a program"
  task :generate_geography_reading_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_geography_reading_activity(ENV['program_id'])
  end

  desc "Create a virtual chat activity and link it into a program"
  task :generate_virtual_chat_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_virtual_chat_activity(ENV['program_id'])
    DemoData::Generator.new.create_virtual_chat_activity_both_genders(ENV['program_id'])
  end

  desc "Create a fib activity with sidebar notes and link it into a program"
  task :generate_fib_activity_with_sidebar => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_fib_activity_with_sidebar_notes(ENV['program_id'])
  end

  desc "Create a composition activity and link it into a program"
  task :generate_composition_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_composition_activity(ENV['program_id'])
  end

  desc "Create a short clips activity and link it into a program"
  task :generate_short_clips_activity => :environment do
    if ENV['program_id'].blank?
      puts "usage: rake demo_data:generate_short_clips_activity program_id=<id> overwrite_media_items=<yes/no ('no' by default, media items won't be overwritten if they exists)>"
      exit(1)
    end

    DemoData::Generator.new.create_short_clips_activity(ENV['program_id'], ENV['overwrite_media_items'])
  end

  desc "Loads allowed file types data from fixtures"
  task :load_allowed_file_types_data => :environment do
    DemoData::Generator.new.load_file_types_fixtures
  end

  desc "Create an interactive tutorial activity and link it into a program"
  task :generate_interactive_tutorial_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_interactive_tutorial_activity(ENV['program_id'])
  end

  desc "Create an reference_activity activity and link it into a program"
  task :generate_reference_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_reference_activity(ENV['program_id'])
  end

  desc "Create an vocab_list_v2 activity and link it into a program"
  task :generate_vocab_list_v2 => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end

    DemoData::Generator.new.create_vocab_list_v2_activity(ENV['program_id'])
  end

  desc "Create a partner chat activity and link it into a program"
  task :generate_partner_chat_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_partner_chat_activity(ENV['program_id'])
  end

  desc "Cleans out all user/activity/response data files"
  task :delete_data_files => :environment do
    cleaner = DemoData::Cleaner.new
    cleaner.delete_all_response_xml_files
    cleaner.delete_all_user_log_csv_files
    cleaner.delete_all_activity_xml_files
  end

  desc "Cleans out all resources"
  task :delete_resources => :environment do
    cleaner = DemoData::Cleaner.new
    cleaner.delete_all_resources
  end

  desc "Create uploaded resources for instructor"
  task :create_uploaded_resources_for_instructor => :environment do
    if ['program_id', 'instructor_username', 'quantity', 'unit_type'].any?{ |key| ENV[key].blank? }
      puts "usage: rake demo_data:create_uploaded_resources_for_instructor program_id=<id> instructor_username=<username> quantity=<#_of_resources> unit_type=<unit|no_unit|unit_range>"
      exit(1)
    end

    generator = DemoData::Generator.new
    generator.create_uploaded_resources(ENV['instructor_username'], ENV['quantity'], ENV['program_id'], ENV['unit_type'])
  end

  desc "Cleans out all course, section, and student work data"
  task :delete_all_courses_and_student_work => :environment do
    DemoData::Cleaner.new.delete_all_courses_and_student_work
  end

  desc "Creates courses, sections, assignments, enrolls students, and creates scores and grades"
  task :create_instructor_data_set => :environment do

    if ['program_id', 'instructor_id'].any?{ |key| ENV[key].blank? }
      puts "usage: rake demo_data:create_instructor_data_set program_id=<id> instructor_id=<id> [short_program_name=<string>]"
      exit(1)
    end
    Dangerfield::Gatekeeper.instance.disabled = false
    generator = DemoData::Generator.new
    generator.create_instructor_data_set(ENV['program_id'], ENV['instructor_id'], ENV['short_program_name'])

    Dangerfield::Gatekeeper.instance.disabled = true
  end

  desc "Creates model demo course for an instructor"
  task :create_model_demo_course => :environment do
    if ['program_id', 'instructor_id', 'student_ids'].any?{ |key| ENV[key].blank? }
      puts "usage: rake demo_data:create_model_demo_course program_id=<id> instructor_id=<id> student_ids=<comma separated ids>"
      exit(1)
    end
    Dangerfield::Gatekeeper.instance.disabled = false
    generator = DemoData::Generator.new
    generator.create_model_demo_course(ENV['program_id'], ENV['instructor_id'], ENV['student_ids'])
    Dangerfield::Gatekeeper.instance.disabled = true
  end

  desc "Create resources with programs and unit associate"
  task :create_resources => :environment do

    generator = DemoData::Generator.new
    generator.create_resources(ENV['program_id'])
  end

  desc "Transform an existing recording activity into a recording_v2 activity"
  task :create_recordingv2_activity => :environment do
    if ['activity_id'].any?{ |key| ENV[key].blank? }
      puts "usage: rake demo_data:create_recordingv2_activity activity_id=<id>"
      exit(1)
    end

    generator = DemoData::Generator.new
    generator.create_recordingv2_activity(ENV['activity_id'])
  end

  desc "Create a two-tier M3 program"
  task :create_two_tier_program => :environment do
    loader = DemoData::Loader.new
    loader.create_content_for_program_with_units_and_lessons(ENV['program_id'], ENV['program_name'], ENV['unit_label'], ENV['lesson_label'])
  end

  desc "changes the last unit of a program to a non-released unit"
  task :set_last_unit_as_not_released => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    generator = DemoData::Generator.new
    generator.set_last_unit_as_not_released(ENV['program_id'])
  end

  desc "Creates a reference activity with reference groups and links it into a program"
  task :generate_cultural_notes_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_cultural_notes_activity(ENV['program_id'])
  end

  desc "Creates a reference activity with an image bank and links it into a program"
  task :generate_adelante_explore_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_adelante_explore_activity(ENV['program_id'])
  end

  desc "Creates a reference activity with a reading preview and links it into a program"
  task :generate_reading_preview_activity => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_reading_preview_activity(ENV['program_id'])
  end

  desc "Creates an exam made up only of multiple-choice subactivities and links it i nto a program"
  task :generate_mc_only_exam => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_mc_only_exam_activity(ENV['program_id'])
  end

  desc "Creates a current events unit for the given program"
  task :generate_current_events_unit => :environment do |task_name|
    if ENV['program_id'].blank?
      puts "usage: rake #{task_name} program_id=<id>"
      exit(1)
    end
    DemoData::Generator.new.create_current_events_unit(ENV['program_id'])
  end


end

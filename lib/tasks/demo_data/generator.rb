# coding: utf-8
require 'tasks/example_data_utils'
require 'tasks/demo_data/assignments'
require 'tasks/demo_data/student'
require_relative '../../../app/lib/file_type_parsable'

module DemoData
  class Generator
    require 'ruby-progressbar'

    include Student
    include Assignments
    include ::ExampleDataUtils
    include ::FileTypeParsable

    def create_instructor_data_set(program_id, instructor_id, short_program_name = '')
      @program    = Program.find(program_id)
      @instructor = Instructor.find(instructor_id)
      @school     = @instructor.schools.first
      puts "starting instructor data setup for #{@instructor.username}"

      base_name = @instructor.username.gsub('_instructor', '')
      base_name += "_#{short_program_name}" if short_program_name.present?

      all_students = ::Student.where("username like '#{base_name}%'").all
      all_students.each do |student|
        student.update!(:last_login_at => 1.week.ago)
      end

      closed_course = create_closed_course
      create_assignment_data(closed_course.sections.first , @program.id, true)

      active_course = create_active_course

      students_per_section = (all_students.size / active_course.reload.sections.size)
      #TODO: Ensure any extra students end up in first section

      active_course.sections.each do |section|
        students = all_students.shift(students_per_section)
        create_assignments_and_grades(section, students)
      end

      make_gradebook_current

      create_announcements(@instructor)
    end

    def course_packages(program_id)
      supersite_plus_level = supersite_level = websam = nil
      Maestro::CoursePackage.all(program_id).each do |package|
        case package.name
        when '01-Supersite' then supersite_level = package.id.to_s
        when '02-Supersite_Plus' then supersite_plus_level = package.id.to_s
        when 'WebSAM' then websam = package.id.to_s
        when /^Supersite$/ then supersite_level = package.id.to_s
        when /^Supersite Plus.*/ then supersite_plus_level = package.id.to_s
        when /^Supersite.*eCuaderno/ then supersite_plus_level = package.id.to_s
        when /^eCuaderno.*/ then websam = package.id.to_s
        when /^WebSAM.*/ then websam = package.id.to_s
        end
      end
      [(supersite_plus_level || supersite_level), websam].compact
    end

    def create_model_demo_course(program_id, instructor_id, student_ids)
      @program    = Program.find(program_id)
      @instructor = Instructor.find(instructor_id)
      @school     = @instructor.schools.first
      puts "starting model course data setup for #{@instructor.username}"

      #rename course if exists and is named as Demo
      course = Course.where(name: "Demo Course",
                            owner_id: @instructor.id,
                            program_id: program_id,
                            school_id: @school.id).first
      if course
        course.update(name: 'Trial Course')
      else
        course = Course.where(name: "Trial Course",
                              owner_id: @instructor.id,
                              program_id: program_id,
                              school_id: @school.id).first
      end

      if course
        if course.assignments.blank?
          section = course.sections.first
          create_model_demo_assignments(@program, course, section)
        end
      else
        course = FactoryBot.create(:course,
                                      owner:       @instructor,
                                      school:      @school,
                                      program_id:  @program.id,
                                      name:        "Trial Course",
                                      start_date:  8.days.ago.to_date,
                                      end_date:    92.days.from_now.to_date,
                                      first_unit:  @program.units.first,
                                      last_unit:   @program.units[4] || @program.units.last
        )

        FactoryBot.create(:category,
                              course: course,
                              name: 'Homework',
                              weighting_percent: 30,
                              rank: 1,
                              max_attempts: 2)
        FactoryBot.create(:category,
                              course: course,
                              name: 'Projects',
                              weighting_percent: 30,
                              rank: 2,
                              max_attempts: 2)
        FactoryBot.create(:category,
                              course: course,
                              name: 'Quizzes',
                              weighting_percent: 40,
                              rank: 3,
                              max_attempts: 2)

        section = create_section(course, class_days = '1,3,5', 'MWF 9:30am - 11:00am', 'Demo Section')
        create_model_demo_assignments(@program, course, section)

        students = ::Student.where(id: student_ids.split(','))
        Enrollment.enroll_demo_students(students, section)
        create_response_xml(students, section)
      end

      Maestro::CourseLicense.create( course.guid, course_packages(program_id) )
    end

    def create_response_xml(students, section)
      section.assignments.each do |assignment|
        activity = assignment.assignable
        if activity.gradable?
          content = activity.content_object
          content.lipsum = Lorem::Base.new('chars', 500).output if content.has_open_ended?
          students.each do |student|
            create_attempt_with_responses(activity, student, section, content)
          end
        end
      end
    end
    private :create_response_xml

    def create_attempt_with_responses(activity, student, section, content)
      attempt = FactoryBot.create(:attempt,
                                      activity: activity,
                                      user: student,
                                      section: section,
                                      cms_activity_id: activity.cms_activity_id,
                                      cms_revision_id: activity.cms_revision_id  )
      attempt.write_results(content.demo_responses, AttemptStatus::CODE_COMPLETED, save_mode = :submitted, start_time = 0, end_time = 0)
    end
    private :create_attempt_with_responses

    def create_model_demo_assignments(program, course, section)
      unit = course.first_unit
      homework_category = course.categories.first

      overdue_date = Date.yesterday
      future_due_date = 30.days.from_now.to_date
      strand_assignment_days = [overdue_date, overdue_date, future_due_date, future_due_date]
      strand_count = 0

      unit.lessons.each do |lesson|
        lesson.strands.each do |strand|
          strand_assignment_days[strand_count % strand_assignment_days.size]
          due_date = strand_assignment_days[strand_count % strand_assignment_days.size]
          strand_count += 1
          potential_activities = strand.descendant_activities
          activities = []
          activities << potential_activities.detect{|activity| !activity.gradable? }
          activities << potential_activities.detect{|activity| activity.gradable? && !activity.instructor_graded? }
          activities << potential_activities.detect{|activity| activity.gradable? && activity.instructor_graded? }
          activities.compact.each do |activity|
            FactoryBot.create(:assignment,
                                  assignable: activity,
                                  section: section,
                                  due_date: due_date,
                                  category: homework_category)
          end
        end
      end
    end
    private :create_model_demo_assignments

    def create_resources(program_id)
      extend ActionView::Helpers

      csv_file   = File.join('db', 'example_data', "resources.csv")
      generic_unit_id = ResourcesTaskHelpers::create_resource_unit_and_lesson(program_id)
      generic_lesson_id = Unit.find(generic_unit_id).lessons.first.id

      resource_count = 0
      DemoData::CSV.rows(csv_file) do |row|
        resource_count += 1
      end

      progress_bar = ProgressBar.new("resources_to_create", resource_count)

      DemoData::CSV.rows(csv_file) do |row|
        source_file_path = row[:source_file_path]

        filename = File.basename(source_file_path)
        ext_name = File.extname(filename)
        description = Lorem::Base.new('words',random_number(10,50)).output

        parent_component = ResourceComponent.find_or_create_by_name_and_program_id(:name => row[:component_name], :program_id => program_id)

        resource_params = { :title                 => row[:clean_title],
                            :program_id            => program_id,
                            :file_name             => filename,
                            :file_type             => file_type(ext_name),
                            :description           => description,
                            :subcomponent_name     => row[:subcomponent_name],
                            :vhl_student_resource  => (row[:is_student_resource].to_s == '1'),
                            :protected             => (row[:is_protected].to_s == '1'),
                            :resource_component_id => parent_component.id
                          }

        if row[:start_unit].blank?
          resource_params[:start_unit_id] = generic_unit_id
          resource_params[:lesson_id] = generic_lesson_id
        else
          unit_id = ResourcesTaskHelpers.unit_for_resource(row[:start_unit], program_id)
          if unit_id
            unit_lessons = Unit.find(unit_id).lessons
            resource_params[:start_unit_id] = unit_id
            resource_params[:lesson_id] = unit_lessons[rand(unit_lessons.size)].id
          end
        end
        resource_params[:end_unit_id] = ResourcesTaskHelpers.unit_for_resource(row[:end_unit], program_id) unless row[:end_unit].blank?

        resource = FactoryBot.create(:resource,  resource_params)

        contents = "Fake contents for #{resource.title} - #{resource.file_name} located at #{resource.file_path}"
        unless File.exist?(resource.file_path)
          DemoData::DataFile.write(resource.file_path, contents)
        end
        progress_bar.inc
      end
      progress_bar.finish
    end

    def create_uploaded_resources(user_name, quantity, program_id, unit_options)
      instructor = Instructor.first(:conditions => {:username => user_name})
      if !instructor || quantity.to_i == 0
        puts "'uploaded resources' where not created for '#{user_name}', you can run this task again with the user created if you need them" unless instructor
        puts "'quantity' must be greater than 0" if quantity.to_i == 0
        return
      end
      quantity = quantity.to_i

      program = Program.find_by_id(program_id)
      units = []
      units = program.units.reject{ |unit| unit.name == "No #{program.unit_label}" }
      possible_file_extensions = ["doc","jpg","pdf","ppt","rtf"]
      resource_components = ResourceComponent.all(:conditions => {:program_id => program_id})
      number_of_components = resource_components.size
      instructor = Instructor.first(:conditions => {:username => 'sample_instructor'})

      resource_params = {}

      resource_params = case unit_options
        when "no_unit" then {:start_unit_id => @unit.id}
        when "unit_range" then {:start_unit_id => program.units.first.id, :end_unit_id => units[random_number(1, program.units.size - 1)].id}
        else {:start_unit_id => program.units.first.id}
      end

      (1..quantity).each do |iterator|
        uploaded_file_name = "uploaded_resource_sample_file_#{iterator}.#{possible_file_extensions[random_number(0, (possible_file_extensions.size - 1))]}"
        name = "Uploaded Resource #{unit_options.gsub('_', ' ').capitalize} N.#{iterator}"
        ext_name = File.extname(uploaded_file_name)
        description = Lorem::Base.new('words',random_number(10,50)).output
        component = resource_components[random_number(0, number_of_components)]
        resource_create_params= {:title => name,
                                 :file_type => file_type(ext_name),
                                 :source => "Instructor",
                                 :uploaded => true,
                                 :owner_id => instructor.id,
                                 :program_id => program_id,
                                 :resource_component_id => component.id,
                                 :file_name => uploaded_file_name,
                                 :description => description}

        resource_create_params.merge!(resource_params)
        resource = FactoryBot.create(:resource,  resource_create_params)
        contents = "Fake contents for #{resource.title} - #{resource.file_name} located at #{resource.file_path}"
        unless File.exist?(resource.file_path)
          DemoData::DataFile.write(resource.file_path, contents)
        end
      end
    end

    def create_virtual_chat_activity_both_genders(program_id)
      unit_index ||= 0 # just use the first unit if we haven't specified one
      lesson = Program.find(program_id).units[unit_index].lessons.first
      cms_activity_id ||= 16
      title ||= 'Preguntas personales Hombre/Mujer - Virtual chat'
      media_list ||= [ "0012/0966/vc_boy.jpg",
                       "0012/0955/DES2e_V1_L05_TXT_VOC_Sim_12_model.mp3",
                       "0012/0956/DES2e_V1_L05_TXT_VOC_Sim_12_p1.mp3",
                       "0012/0957/DES2e_V1_L05_TXT_VOC_Sim_12_p2.mp3",
                       "0012/0958/DES2e_V1_L05_TXT_VOC_Sim_12_p3.mp3",
                       "0012/0959/DES2e_V1_L05_TXT_VOC_Sim_12_p4.mp3",
                       "0012/0960/DES2e_V1_L05_TXT_VOC_Sim_12_p5.mp3",
                       "0012/0961/DES2e_V1_L05_TXT_VOC_Sim_12_p6.mp3",
                       "0012/0962/DES2e_V1_L05_TXT_VOC_Sim_12_p7.mp3",
                       "0012/0963/DES2e_V1_L05_TXT_VOC_Sim_12_p8.mp3",
                       "0012/0964/DES2e_V1_L05_TXT_VOC_Sim_12_p9.mp3",
                       "0012/0965/DES2e_V1_L05_TXT_VOC_Sim_12_p10.mp3",
                       # female audios
                       "0010/9678/L01_06_Pronunciacion_Ex2_01_prompt.mp3",
                       "0010/9679/L01_06_Pronunciacion_Ex2_02_prompt.mp3",
                       "0010/9680/L01_06_Pronunciacion_Ex2_03_prompt.mp3",
                       "0010/9681/L01_06_Pronunciacion_Ex2_04_prompt.mp3",
                       "0010/9682/L01_06_Pronunciacion_Ex2_05_prompt.mp3",
                       "0010/9683/L01_06_Pronunciacion_Ex2_06_prompt.mp3",
                       "0010/9684/L01_06_Pronunciacion_Ex2_07_prompt.mp3",
                       "0010/9685/L01_06_Pronunciacion_Ex2_08_prompt.mp3",
                       "0010/9686/L01_06_Pronunciacion_Ex2_09_prompt.mp3",
                       "0010/9687/L01_06_Pronunciacion_Ex2_10_prompt.mp3" ]

      strand = lesson.strands.first
      # the second activity from the strand, so, vchat with one gender
      # and vchat with two genders will live on the same strand
      copy_from_activity = strand.descendant_activities[1]
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = "virtual_chat"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40050 + cms_activity_id
      activity.points_possible = 15

      source_filename ||= "virtual_chat_content_descubre_two_genders.xml"
      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      # generate study plan
      StudyPlanConceptsCreator.new(activity, program_id).create
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_study_plan_activity(program_id)
      unit_index = 0
      cms_activity_id = 50
      title = 'study plan practice test'
      source_filename = 'study_plan_practice_test_activity.xml'
      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands.first
      copy_from_activity = strand.descendant_activities.first

      activity = copy_from_activity.clone
      activity.activity_type = "study_plan_practice_test"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40010 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      # generate study plan
      StudyPlanConceptsCreator.new(activity, program_id).create
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_true_false_enhanced_activity(program_id)
      unit_index = 0
      cms_activity_id = 50
      title = 'true false enhanced'
      source_filename = 'true_false_enhanced.xml'
      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands.first
      copy_from_activity = strand.descendant_activities.first

      activity = copy_from_activity.clone
      activity.activity_type = 'true_false_enhanced'
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40010 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('spec', 'fixtures', 'xml', source_filename)
      file_contents = File.read( input_file )
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_video_virtual_chat_activity(program_id, poster_format)
      unit_index = 0
      cms_activity_id = 17
      title = "Video Virtual Chat Example #{poster_format}"
      source_filename = "video_virtual_chat_activity.xml"

      media_list = ['0017/1435/rBeato-still.jpg',
                    '0017/1436/R-Beato-still2.png',
                    '0017/1426/L04.1a_M3-16x9_low.mp4',
                    '0017/1427/L04.1b_M3-16x9_low.mp4',
                    '0017/1428/L04.1c_M3-16x9_low.mp4',
                    '0017/1429/L04.1_M3-16x9_low.mp4',
                    '0017/1457/VOL1e_v2_L04_VOC_01_vChats-16x9.mp4',
                    '0017/1458/VOL1e_v2_L04_VOC_02_vChats-16x9.mp4',
                    '0017/1459/VOL1e_v2_L04_VOC_03_vChats-16x9.mp4',
                    '0017/1460/VOL1e_v2_L04_VOC_04_vChats-16x9.mp4']

      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = (poster_format == 'png' ? lesson.strands.first : lesson.strands.second)
      copy_from_activity = strand.descendant_activities.first
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = "video_virtual_chat"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = (poster_format == 'png' ? 40011 : 40010) + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      file_contents.gsub! 'REPLACEMEPLEASE', (poster_format == 'png' ? '171436' : '171435')
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} with id #{activity.id} created in #{strand.name}!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_tutorial_vocab_html5_activity(program_id)
      unit_index = 0
      cms_activity_id = 17
      title = "Vocab Tutorial Html5 Activity"
      source_filename = "tutorial_vocab_html5.xml"

      media_list = ['0017/5691/VIS5e_L01_01_voc_tutorial.html5_vocab_tutorial.zip']

      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = (program_id.to_i.even? ? lesson.strands.first : lesson.strands.second)
      copy_from_activity = strand.descendant_activities.first
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = "tutorial_vocab_html5"

      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = (program_id.to_i.even? ? 40011 : 40010) + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )

      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }

      media_item = activity.content_object.tutorial_media_item
      media_item.media_type = 'vocab_tutorial_html5'

      media_item.save!
      media_item.payload = File.read(media_item.send(:media_file_path))
      activity.save!

      puts "#{activity.title} with id #{activity.id} created in #{strand.name}!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end


    def create_video_virtual_chat_activity_with_gender(program_id)
      unit_index = 0
      cms_activity_id = 17
      title = "Video Virtual Chat Example (gender)"
      source_filename = "video_virtual_chat_activity_with_gender.xml"

      media_list = ['0017/1435/rBeato-still.jpg',
                    '0017/1436/R-Beato-still2.png',
                    '0017/1426/L04.1a_M3-16x9_low.mp4',
                    '0017/1427/L04.1b_M3-16x9_low.mp4',
                    '0017/1428/L04.1c_M3-16x9_low.mp4',
                    '0017/1429/L04.1_M3-16x9_low.mp4']

      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = (program_id.to_i.even? ? lesson.strands.first : lesson.strands.second)
      copy_from_activity = strand.descendant_activities.first
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = "video_virtual_chat"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = (program_id.to_i.even? ? 40011 : 40010) + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )

      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!

      puts "#{activity.title} with id #{activity.id} created in #{strand.name}!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_cumulative_matching_activity(program_id)
      unit_index = 0
      cms_activity_id = 17
      title = 'Cumulative Matching Example'
      source_filename = "cumulative_matching_activity.xml"
      media_list = ["0013/7024/Vocab1.png",
                    "0013/7025/Vocab2.png",
                    "0013/7026/Vocab3.png",
                    "0013/7027/Vocab4.png",
                    "0013/7028/Vocab5.png",
                    "0013/7029/Vocab6.png",
                    "0013/7030/Vocab7.png",
                    "0013/7031/Vocab8.png",
                    "0013/7032/Vocab9.png",
                    "0013/7033/Vocab10.png",
                    "0013/7034/Vocab11.png",
                    "0013/7035/Vocab12.png",
                    "0012/0989/S01_T04.mp3" ]
      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands.first
      copy_from_activity = strand.descendant_activities.first
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = "cumulative_matching"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40010 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_learning_engine_diagnostic_activity(program_id)
      unit_index = 0
      cms_activity_id = 18
      source_filename = "learning_engine_diagnostic_activity.xml"
      media_list = ["0013/6475/SGT_proto_011614_Andy.mp4",
                    "0013/8699/SpGT_L05.1_040614.mp4",
                    "0013/6813/AVE4e_L05_APP_VOC_el_aeropuerto.mp3",
                    "0013/7077/AVE4e_L05_APP_VOC_confirmar_una_reservacion.mp3",
      ]
      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[3] # estructura strand
      copy_from_activity = strand.descendant_activities.first
      copy_media_from_cms(media_list)
      MediaItem.find(136475).update!(:width => 900, :height => 526)
      MediaItem.find(138699).update!(:width => 900, :height => 526)

      activity = copy_from_activity.clone
      activity.activity_type = "learning_engine"
      activity.title = 'Learning Engine Diagnostic Example'
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40010 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_learning_engine_record_and_compare_activity(program_id)
      unit_index = 0
      cms_activity_id = 19
      source_filename = "learning_engine_record_and_compare.xml"
      media_list = ["0014/0313/L05-animation-v2-1280x720.mp4",
                    "0013/8676/ARC_VOL1e_L05_EXPLORE_PRON_cerveza.mp3",
                    "0013/8677/ARC_VOL1e_L05_EXPLORE_PRON_bueno.mp3",
                    "0013/8678/ARC_VOL1e_L05_EXPLORE_PRON_bonito.mp3",
                    "0013/8679/ARC_VOL1e_L05_EXPLORE_PRON_abril.mp3",
                    "0013/8680/ARC_VOL1e_L05_EXPLORE_PRON_vela.mp3",
                    "0013/8681/ARC_VOL1e_L05_EXPLORE_PRON_viajar.mp3",
                    "0013/8682/ARC_VOL1e_L05_EXPLORE_PRON_vivir.mp3",
                    "0013/8683/ARC_VOL1e_L05_EXPLORE_PRON_deber.mp3",
                    "0013/8684/ARC_VOL1e_L05_EXPLORE_PRON_novio.mp3",
                    "0013/8685/ARC_VOL1e_L05_EXPLORE_PRON_tambien.mp3",
                    "0013/8686/ARC_VOL1e_L05_EXPLORE_PRON_declive.mp3",
                    "0013/8687/ARC_VOL1e_L05_EXPLORE_PRON_biblioteca.mp3",
                    "0013/8688/ARC_VOL1e_L05_EXPLORE_PRON_bola.mp3",
                    "0013/8689/ARC_VOL1e_L05_EXPLORE_PRON_voleibol.mp3",
                    "0013/8690/ARC_VOL1e_L05_EXPLORE_PRON_Veronica_y_su_esposo.mp3",
                    "0013/8691/ARC_VOL1e_L05_EXPLORE_PRON_Caribe.mp3",
                    "0013/8692/ARC_VOL1e_L05_EXPLORE_PRON_Benito_es_de_Boqueron.mp3",
                    "0013/8693/ARC_VOL1e_L05_EXPLORE_PRON_investigar.mp3"]
      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[1].children[1] # pronunciation strand under fotonovela
      copy_from_activity = strand.descendant_activities[2] # this should be the third activity, after pronunciation explore
      copy_media_from_cms(media_list)
      activity = copy_from_activity.clone
      MediaItem.find(140313).update!(:width => 900, :height => 526)

      activity = copy_from_activity.clone
      activity.activity_type = "learning_engine"
      activity.title = 'Pronunciation Learn Tutorial with Record and Compare'
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40010 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_learning_engine_interactive_vocab_chart_activity(program_id)
      unit_index = 0
      cms_activity_id = 20
      source_filename = "learning_engine_interactive_vocab_chart_activity.xml"
      media_list = ["0013/6798/AVE4e_L05_APP_P002_CO_68003_las_vacaciones.jpg",
                    "0013/6799/AVE4e_L05_APP_P010_MF_649-03292476_estar_de_vacaciones.jpg",
                    "0013/6800/AVE4e_L05_APP_P011_DR_2984579_ir_de_vacaciones.jpg",
                    "0013/6801/AVE4e_L05_APP_P028_CU_CZP100808-149_ir_en_automovil.jpg",
                    "0013/6802/AVE4e_L05_APP_P031_CU_OAS0949_ir_en_taxi.jpg",
                    "0013/6803/AVE4e_L05_APP_P033_DR_26281386_ir_en_barco.jpg",
                    "0013/6804/AVE4e_L05_APP_P035_DR_2659262_ir_en_motocicleta.jpg",
                    "0013/6806/AVE4e_L05_APP_P037_CU_OAS0916_ir_en_autobus.jpg",
                    "0013/6810/AVE4e_L05_APP_P044_CU_VAB090409-052_ir_en_avion.jpg",
                    "0013/6816/AVE4e_L05_APP_VOC_estar_de_vacaciones.mp3",
                    "0013/6817/AVE4e_L05_APP_VOC_ir_de_vacaciones.mp3",
                    "0013/6818/AVE4e_L05_APP_VOC_ir_en_autobus.mp3",
                    "0013/6819/AVE4e_L05_APP_VOC_ir_en_automovil.mp3",
                    "0013/6820/AVE4e_L05_APP_VOC_ir_en_avion.mp3",
                    "0013/6821/AVE4e_L05_APP_VOC_ir_en_barco.mp3",
                    "0013/6822/AVE4e_L05_APP_VOC_ir_en_motocicleta.mp3",
                    "0013/6823/AVE4e_L05_APP_VOC_ir_en_taxi.mp3",
                    "0013/6827/AVE4e_L05_APP_VOC_las_vacaciones.mp3",
                    "0013/8561/vocab_grammar_chart.mp4"]
      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[3] # estructura strand
      copy_from_activity = strand.descendant_activities[1] #this should be the second activity in the strand
      copy_media_from_cms(media_list)
      MediaItem.find(138561).update!(:width => 900, :height => 526)

      activity = copy_from_activity.clone
      activity.activity_type = "learning_engine"
      activity.title = 'Vocabulary chart: <b>-er</b> verbs'
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40010 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_interactive_map_activity(program_id)
      Activity.where(activity_type: 'interactive_map').map(&:destroy)
      unit_index = 0
      cms_activity_id = 21
      title = 'Interactive Map Activity'
      source_filename = 'interactive_map_activity.xml'
      media_list = [
        "0012/4610/DES2e_V2_TXT_L04_PANO_MAP_p158.png",
        "0012/0144/DES2e_V1_TXT_L05_PANO_MAP_p186.png",
        "0014/0292/VOL1e_L05_EXPLORE_GEO_map_San_Juan.mp3",
        # cities
        "0014/0285/VOL1e_L05_EXPLORE_GEO_map_Mayaguez.mp3",
        "0014/0286/VOL1e_L05_EXPLORE_GEO_map_Ponce.mp3",
        "0014/0288/VOL1e_L05_EXPLORE_GEO_map_Arecibo.mp3",
        "0014/0289/VOL1e_L05_EXPLORE_GEO_map_Fajardo.mp3",
        "0014/0290/VOL1e_L05_EXPLORE_GEO_map_Bayamon.mp3",
        # points of interest audio
        "0014/0283/VOL1e_L05_EXPLORE_GEO_map_Faro_en_Arecibo.mp3",
        "0014/0287/VOL1e_L05_EXPLORE_GEO_map_Playa_en_San_Juan.mp3",
        "0014/0284/VOL1e_L05_EXPLORE_GEO_map_Iglesia_en_Ponce.mp3",
        "0014/0291/VOL1e_L05_EXPLORE_GEO_map_Pescadores_en_Mayaguez.mp3",
        # point of interest images
        "0014/2389/VOL1e_L05_EXPLORE_GEO_p186_Mayaguez.jpg",
        "0014/2391/VOL1e_L05_EXPLORE_GEO_p186_Ponce.jpg",
        "0014/2393/VOL1e_L05_EXPLORE_GEO_p186_San_Juan.jpg",
        "0014/2387/VOL1e_L05_EXPLORE_GEO_p186_Arecibo.jpg"
      ]

      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[4].children[2] # Panorama substrand within Adelante strand
      copy_from_activity = strand.descendant_activities.first
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = 'interactive_map'
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read(input_file)
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w') { |file| file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "file path: #{activity.content_filepath}"
    end

    def create_geography_reading_activity(program_id)
      unit_index = 0
      cms_activity_id = 34
      title = 'Geography Reading Activity'
      source_filename = 'geography_reading_activity.xml'
      media_list = ['0014/0396/puerto_rico_flag.png', '0014/0397/puerto_rico_caves.jpg']

      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[4].children[2]
      copy_from_activity = strand.descendant_activities[1]
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = 'reference_activity'
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read(input_file)
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open(activity.content_filepath, 'w') { |file| file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "file path: #{activity.content_filepath}"
    end

    def create_pronunciation_explore_activity(program_id)
      unit_index = 0
      cms_activity_id = 22
      title = 'Pronunciation Explore Activity'
      source_filename = 'pronunciation_explore_activity.xml' # to-do: use the real one
      media_list = [
        "0013/6813/AVE4e_L05_APP_VOC_el_aeropuerto.mp3",
        "0013/7077/AVE4e_L05_APP_VOC_confirmar_una_reservacion.mp3",
        "0013/7078/AVE4e_L05_APP_VOC_el_aeropuerto.mp3",
        "0013/7079/AVE4e_L05_APP_VOC_el_agente_de_viajes.mp3",
        "0013/7080/AVE4e_L05_APP_VOC_el_avion.mp3",
        "0013/7081/AVE4e_L05_APP_VOC_el_inspector_de_aduanas.mp3",
        "0013/7082/AVE4e_L05_APP_VOC_el_pasaporte.mp3",
        "0013/7083/AVE4e_L05_APP_VOC_el_viajero.mp3",
        "0013/7084/AVE4e_L05_APP_VOC_la_agencia_de_viajes.mp3",
        "0013/7085/AVE4e_L05_APP_VOC_la_agente_de_viajes.mp3",
        "0013/7086/AVE4e_L05_APP_VOC_la_inspectora_de_aduanas.mp3",
        "0013/7087/AVE4e_L05_APP_VOC_la_viajera.mp3",
        "0013/7088/AVE4e_L05_APP_VOC_sacar_fotos.mp3",
        "0013/8676/ARC_VOL1e_L05_EXPLORE_PRON_cerveza.mp3",
        "0013/8677/ARC_VOL1e_L05_EXPLORE_PRON_bueno.mp3",
        "0013/8678/ARC_VOL1e_L05_EXPLORE_PRON_bonito.mp3",
        "0013/8679/ARC_VOL1e_L05_EXPLORE_PRON_abril.mp3",
        "0013/8680/ARC_VOL1e_L05_EXPLORE_PRON_vela.mp3",
        "0013/8681/ARC_VOL1e_L05_EXPLORE_PRON_viajar.mp3",
        "0013/8682/ARC_VOL1e_L05_EXPLORE_PRON_vivir.mp3",
        "0013/8683/ARC_VOL1e_L05_EXPLORE_PRON_deber.mp3",
        "0013/8684/ARC_VOL1e_L05_EXPLORE_PRON_novio.mp3",
        "0013/8685/ARC_VOL1e_L05_EXPLORE_PRON_tambien.mp3",
        "0013/8686/ARC_VOL1e_L05_EXPLORE_PRON_declive.mp3",
        "0013/8687/ARC_VOL1e_L05_EXPLORE_PRON_biblioteca.mp3",
        "0013/8688/ARC_VOL1e_L05_EXPLORE_PRON_bola.mp3",
        "0013/8689/ARC_VOL1e_L05_EXPLORE_PRON_voleibol.mp3",
        "0013/8690/ARC_VOL1e_L05_EXPLORE_PRON_Veronica_y_su_esposo.mp3",
        "0013/8691/ARC_VOL1e_L05_EXPLORE_PRON_Caribe.mp3",
        "0013/8692/ARC_VOL1e_L05_EXPLORE_PRON_Benito_es_de_Boqueron.mp3",
        "0013/8693/ARC_VOL1e_L05_EXPLORE_PRON_investigar.mp3"
      ]

      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[1].children[1] # pronunciation strand under fotonovela
      copy_from_activity = strand.descendant_activities.first
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = 'fill_in_the_blanks' #change for the real one
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read(input_file)
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w') { |file| file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_pronunciation_explore_alphabet_activity(program_id)
      unit_index = 0
      cms_activity_id = 33
      title = 'Pronunciation explore: Alphabet'
      source_filename = 'pronunciation_explore_alphabet_activity.xml'
      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[1].children[1] # pronunciation strand under fotonovela
      copy_from_activity = strand.descendant_activities[1]
      media_list = ["0014/0334/ARC_VOL1e_L01_EXPLORE_PRON_igualmente.mp3",
                    "0014/0339/ARC_VOL1e_L01_EXPLORE_PRON_chico.mp3",
                    "0014/0346/ARC_VOL1e_L01_EXPLORE_PRON_hola.mp3",
                    "0014/0349/ARC_VOL1e_L01_EXPLORE_PRON_kilometro.mp3",
                    "0014/0352/ARC_VOL1e_L01_EXPLORE_PRON_bien_problema.mp3",
                    "0014/0357/ARC_VOL1e_L01_EXPLORE_PRON_cosa_cero.mp3",
                    "0014/0365/ARC_VOL1e_L01_EXPLORE_PRON_adios.mp3",
                    "0014/0367/ARC_VOL1e_L01_EXPLORE_PRON_estudiante.mp3",
                    "0014/0370/ARC_VOL1e_L01_EXPLORE_PRON_Javier.mp3",
                    "0014/0375/ARC_VOL1e_L01_EXPLORE_PRON_dario_nada.mp3",
                    "0014/0383/ARC_VOL1e_L01_EXPLORE_PRON_gracias_Gerardo_regular.mp3",
                    "0014/0389/ARC_VOL1e_L01_EXPLORE_PRON_foto.mp3",
                    "0014/0337/ARC_VOL1e_L01_EXPLORE_PRON_d.mp3",
                    "0014/0340/ARC_VOL1e_L01_EXPLORE_PRON_ch.mp3",
                    "0014/0344/ARC_VOL1e_L01_EXPLORE_PRON_g.mp3",
                    "0014/0355/ARC_VOL1e_L01_EXPLORE_PRON_j.mp3",
                    "0014/0358/ARC_VOL1e_L01_EXPLORE_PRON_c.mp3",
                    "0014/0362/ARC_VOL1e_L01_EXPLORE_PRON_f.mp3",
                    "0014/0372/ARC_VOL1e_L01_EXPLORE_PRON_b.mp3",
                    "0014/0381/ARC_VOL1e_L01_EXPLORE_PRON_e.mp3",
                    "0014/0385/ARC_VOL1e_L01_EXPLORE_PRON_h.mp3",
                    "0014/0390/ARC_VOL1e_L01_EXPLORE_PRON_a.mp3",
                    "0014/0391/ARC_VOL1e_L01_EXPLORE_PRON_k.mp3" ]
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = 'pronunciation_explore'
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read(input_file)
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open(activity.content_filepath, 'w') { |file| file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "file path: #{activity.content_filepath}"
    end

    def create_virtual_chat_activity(program_id)

      if program_id.to_i == 53 # Aventuras
        unit_index = 3 # lesson 4 is the demo lesson for aventuras
        cms_activity_id = 23
        title = 'Preguntas - Virtual chat'
        source_filename = "virtual_chat_content_aventuras.xml"
        media_list = [ "0012/0994/aventuras_virtual_partner.jpg",
                       "0012/0989/S01_T04.mp3",
                       "0012/0990/S02_T03.mp3",
                       "0012/0991/S03_T02.mp3",
                       "0012/0992/S04_T01.mp3",
                       "0012/0993/S05_T04.mp3" ]
      elsif program_id.to_i == 56
        unit_index = 4 # lesson 5 is the demo lesson for descubre, level 1
      end

      unit_index ||= 0 # just use the first unit if we haven't specified one
      lesson = Program.find(program_id).units[unit_index].lessons.first
      cms_activity_id ||= 31
      title ||= 'Preguntas personales - Virtual chat'
      source_filename ||= "virtual_chat_content_descubre.xml"
      media_list ||= [ "0012/0966/vc_boy.jpg",
                       "0012/0955/DES2e_V1_L05_TXT_VOC_Sim_12_model.mp3",
                       "0012/0956/DES2e_V1_L05_TXT_VOC_Sim_12_p1.mp3",
                       "0012/0957/DES2e_V1_L05_TXT_VOC_Sim_12_p2.mp3",
                       "0012/0958/DES2e_V1_L05_TXT_VOC_Sim_12_p3.mp3",
                       "0012/0959/DES2e_V1_L05_TXT_VOC_Sim_12_p4.mp3",
                       "0012/0960/DES2e_V1_L05_TXT_VOC_Sim_12_p5.mp3",
                       "0012/0961/DES2e_V1_L05_TXT_VOC_Sim_12_p6.mp3",
                       "0012/0962/DES2e_V1_L05_TXT_VOC_Sim_12_p7.mp3",
                       "0012/0963/DES2e_V1_L05_TXT_VOC_Sim_12_p8.mp3",
                       "0012/0964/DES2e_V1_L05_TXT_VOC_Sim_12_p9.mp3",
                       "0012/0965/DES2e_V1_L05_TXT_VOC_Sim_12_p10.mp3" ]

      strand = lesson.strands.first
      copy_from_activity = strand.descendant_activities.first
      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = "virtual_chat"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_fib_activity_with_sidebar_notes(program_id)
      if program_id.to_i == 53 # Aventuras
        unit_index = 3 # lesson 4 is the demo lesson for aventuras
        cms_activity_id = 24
        title = 'Escribir (Sidebar notes)'
        source_filename = "fill_in_the_blanks_with_sidebar_notes.xml"

      elsif program_id.to_i == 56
        unit_index = 4 # lesson 5 is the demo lesson for descubre, level 1
      end

      unit_index ||= 0 # just use the first unit if we haven't specified one
      program = Program.find(program_id)
      lesson = program.units[unit_index].lessons.first
      cms_activity_id ||= 32
      title = 'Escribir (Sidebar notes)'
      source_filename ||= "fill_in_the_blanks_with_sidebar_notes.xml"
      #third strand in order to avoid overwriting vchat activity
      strand = lesson.strands[2]
      copy_from_activity = strand.descendant_activities.first

      activity = copy_from_activity.clone
      activity.activity_type = "composition"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!

      # add the activity to course library
      #program.courses.each{ |course| CourseLibraryActivity.create(:course => course, :activity => activity) }

      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_fib_activity_with_sidebar_notes(program_id)
      if program_id.to_i == 53 # Aventuras
        unit_index = 3 # lesson 4 is the demo lesson for aventuras
        cms_activity_id = 5
        title = 'Escribir (Sidebar notes)'
        source_filename = "fill_in_the_blanks_with_sidebar_notes.xml"

      elsif program_id.to_i == 56
        unit_index = 4 # lesson 5 is the demo lesson for descubre, level 1
      end

      unit_index ||= 0 # just use the first unit if we haven't specified one
      program = Program.find(program_id)
      lesson = program.units[unit_index].lessons.first
      cms_activity_id ||= 6
      title = 'Escribir (Sidebar notes)'
      source_filename ||= "fill_in_the_blanks_with_sidebar_notes.xml"
      #third strand in order to avoid overwriting vchat activity
      strand = lesson.strands[2]
      copy_from_activity = strand.descendant_activities.first

      activity = copy_from_activity.clone
      activity.activity_type = "composition"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!

      # add the activity to course library
      program.courses.each{ |course| CourseLibraryActivity.create(:course => course, :activity => activity) }

      puts "#{activity.title} created!"
    end

    def create_composition_activity(program_id)

      if program_id.to_i == 53 # Aventuras
        unit_index = 3 # lesson 4 is the demo lesson for aventuras
        cms_activity_id = 25
        title = 'Composition Activity'
        source_filename = "composition_activity.xml"

      elsif program_id.to_i == 56
        unit_index = 4 # lesson 5 is the demo lesson for descubre, level 1
      end

      unit_index ||= 0 # just use the first unit if we haven't specified one
      lesson = Program.find(program_id).units[unit_index].lessons.first
      cms_activity_id ||= 33
      title ||= 'Composition Activity'
      source_filename ||= "composition_activity.xml"
      #second strand in order to avoid overwriting vchat activity
      strand = lesson.strands[1]
      copy_from_activity = strand.descendant_activities.first

      activity = copy_from_activity.clone
      activity.activity_type = "composition"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_short_clips_activity(program_id, overwrite_media_items)
      unit_index ||= 0 # just use the first unit if we haven't specified one
      lesson = Program.find(program_id).units[unit_index].lessons.first
      cms_activity_id ||= 26
      title ||= 'Short Clips Activity'
      source_filename ||= "short_clips.xml"
      #put in second strand, which is fotonovela
      strand = lesson.strands[1]
      copy_from_activity = strand.descendant_activities.first

      media_list = [
        "0011/9987/DES2e_V1_L05_VOC__toma_fotos_tomar_.mp3",
        "0013/6813/AVE4e_L05_APP_VOC_el_aeropuerto.mp3",
        "0013/7077/AVE4e_L05_APP_VOC_confirmar_una_reservacion.mp3",
        "0013/7078/AVE4e_L05_APP_VOC_el_aeropuerto.mp3",
        "0013/7079/AVE4e_L05_APP_VOC_el_agente_de_viajes.mp3",
        "0013/7080/AVE4e_L05_APP_VOC_el_avion.mp3",
        "0013/7081/AVE4e_L05_APP_VOC_el_inspector_de_aduanas.mp3",
        "0013/7082/AVE4e_L05_APP_VOC_el_pasaporte.mp3",
        "0013/7083/AVE4e_L05_APP_VOC_el_viajero.mp3",
        "0013/7084/AVE4e_L05_APP_VOC_la_agencia_de_viajes.mp3",
        "0013/7085/AVE4e_L05_APP_VOC_la_agente_de_viajes.mp3",
        "0013/7086/AVE4e_L05_APP_VOC_la_inspectora_de_aduanas.mp3",
        "0013/7087/AVE4e_L05_APP_VOC_la_viajera.mp3",
        "0013/7088/AVE4e_L05_APP_VOC_sacar_fotos.mp3",
        "0013/7790/VOL1e_L05_EXPLORE_VEPI_EU_a_nombre_de_quien_UPDATE.mp3",
        "0013/7791/VOL1e_L05_EXPLORE_VEPI_EU_es_fabuloso_UPDATE.mp3",
        "0013/7792/VOL1e_L05_EXPLORE_VEPI_EU_sigo_enojado_contigo_UPDATE.mp3",
        "0013/7793/VOL1e_L05_EXPLORE_VEPI_EU_estoy_confundida_UPDATE.mp3",
        "0013/7795/VOL1e_L05_EXPLORE_VEPI_EU_yo_estoy_un_poco_cansada_UPDATE.mp3",
        "0013/7796/VOL1e_L05_EXPLORE_VEPI_EU_ahora_lo_veo_aqui_esta_diaz_UPDATE.mp3",
        "0013/7797/VOL1e_L05_EXPLORE_VEPI_EU_entonces_UPDATE.mp3",
        "0013/7798/VOL1e_L05_EXPLORE_VEPI_EU_el_grito_UPDATE.mp3",
        "0013/7799/VOL1e_L05_EXPLORE_VEPI_EU_es_estupendo_UPDATE.mp3",
        "0013/7800/VOL1e_L05_EXPLORE_VEPI_EU_aqui_estan_las_llaves_UPDATE.mp3",
        "0013/7801/VOL1e_L05_EXPLORE_VEPI_EU_no_esta_nada_mal_el_hotel_UPDATE.mp3",
        "0013/7802/VOL1e_L05_EXPLORE_VEPI_EU_es_fenomenal_UPDATE.mp3",
        "0013/7803/VOL1e_L05_EXPLORE_VEPI_EU_la_crema_de_afeitar_UPDATE.mp3",
        "0013/7804/VOL1e_L05_EXPLORE_VEPI_EU_dos_habitaciones_en_el_primer_piso_para_seis_huespedes_UPDATE.mp3",
        "0013/7805/VOL1e_L05_EXPLORE_VEPI_EU_es_maravilloso_UPDATE.mp3",
        "0013/7806/VOL1e_L05_EXPLORE_VEPI_EU_es_igual_UPDATE.mp3",
        "0013/7807/VOL1e_L05_EXPLORE_VEPI_EU_todavia_estoy_enojada_contigo_UPDATE.mp3",
        "0013/7808/VOL1e_L05_EXPLORE_VEPI_EU_sigo_enojada_contigo_UPDATE.mp3",
        "0013/7809/VOL1e_L05_EXPLORE_VEPI_EU_es_excelente_UPDATE.mp3",
        "0013/7810/VOL1e_L05_EXPLORE_VEPI_EU_yo_estoy_un_poco_cansado_UPDATE.mp3",
        "0013/7811/VOL1e_L05_EXPLORE_VEPI_EU_el_balde_UPDATE.mp3",
        "0013/7812/VOL1e_L05_EXPLORE_VEPI_EU_todo_esta_tan_limpio_y_comodo_UPDATE.mp3",
        "0013/7813/VOL1e_L05_EXPLORE_VEPI_EU_tenemos_una_reservacion_UPDATE.mp3",
        "0013/7814/VOL1e_L05_EXPLORE_VEPI_EU_el_frente_UPDATE.mp3",
        "0013/7815/VOL1e_L05_EXPLORE_VEPI_EU_es_perfecto_UPDATE.mp3",
        "0013/7816/VOL1e_L05_EXPLORE_VEPI_EU_es_increible_UPDATE.mp3",
        "0013/7817/VOL1e_L05_EXPLORE_VEPI_EU_la_temporada_UPDATE.mp3",
        "0013/7818/VOL1e_L05_EXPLORE_VEPI_EU_estoy_confundido_UPDATE.mp3",
        "0013/7819/VOL1e_L05_EXPLORE_VEPI_EU_en_que_puedo_servirles_UPDATE.mp3",
        "0013/7820/VOL1e_L05_EXPLORE_VEPI_EU_quizas_lopez_tal_vez_diaz_UPDATE.mp3",
        "0013/7821/VOL1e_L05_EXPLORE_VEPI_EU_el_frente_frio_UPDATE.mp3",
        "0013/7822/VOL1e_L05_EXPLORE_VEPI_EU_es_magnifico_UPDATE.mp3",
        "0013/7823/VOL1e_L05_EXPLORE_VEPI_EU_todavia_estoy_enojado_contigo_UPDATE.mp3",
        "0013/7824/VOL1e_L05_EXPLORE_VEPI_EU_afuera_UPDATE.mp3",
        "0013/7856/VOL1e_L05_EXPLORE_VEPI_clip1.jpg",
        "0013/7857/VOL1e_L05_EXPLORE_VEPI_clip2.jpg",
        "0013/7858/VOL1e_L05_EXPLORE_VEPI_clip3.jpg",
        "0013/7859/VOL1e_L05_EXPLORE_VEPI_clip4.jpg",
        "0013/7860/VOL1e_L05_EXPLORE_VEPI_clip5.jpg",
        "0013/7861/VOL1e_L05_EXPLORE_VEPI_clip6.jpg",
        "0013/7862/VOL1e_L05_EXPLORE_VEPI_clip7.jpg",
        "0013/7863/VOL1e_L05_EXPLORE_VEPI_clip8.jpg",
        "0013/7864/VOL1e_L05_EXPLORE_VEPI_clip9.jpg",
        "0013/7865/VOL1e_L05_EXPLORE_VEPI_clip10.jpg",
        "0013/7738/anna_maria.png",
        "0013/7739/empleado.png",
        "0013/7740/felipe.png",
        "0013/7741/jimena.png",
        "0013/7742/juan_carlos.png",
        "0013/7743/marie_fuentes.png",
        "0013/7744/marisa.png",
        "0013/7745/maru.png",
        "0013/7746/miguel.png",
        "0013/7846/VOL1e_L05_LEARN_VEPI_clip01.mp4",
         "0013/7847/VOL1e_L05_LEARN_VEPI_clip02.mp4",
         "0013/7848/VOL1e_L05_LEARN_VEPI_clip03.mp4",
         "0013/7849/VOL1e_L05_LEARN_VEPI_clip04.mp4",
         "0013/7850/VOL1e_L05_LEARN_VEPI_clip05.mp4",
         "0013/7851/VOL1e_L05_LEARN_VEPI_clip06.mp4",
         "0013/7852/VOL1e_L05_LEARN_VEPI_clip07.mp4",
         "0013/7853/VOL1e_L05_LEARN_VEPI_clip08.mp4",
         "0013/7854/VOL1e_L05_LEARN_VEPI_clip09.mp4",
         "0013/7855/VOL1e_L05_LEARN_VEPI_clip10.mp4"
      ]

      copy_media_from_cms(media_list, overwrite_media_items)

      MediaItem.find([137846, 137847, 137848, 137849, 137850, 137851, 137852, 137853, 137854, 137855]).each do |media_item|
        media_item.update!(:width => 480, :height => 272)
      end

      activity = copy_from_activity.clone
      activity.activity_type = "short_clips"
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read( input_file )
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_interactive_tutorial_activity(program_id)
      lesson = Program.find(program_id).units.first.lessons.first
      strand = lesson.strands.first
      copy_from_activity = strand.descendant_activities.first
      copy_media_from_cms(['0012/0987/FGT_LO2A_1_010213b_854x480_2kfps_strong_denoise.mp4'])
      copy_media_from_cms(['0012/7765/PRO2e_U01B.1_TXT_tutorial_video.mp4'])
      MediaItem.find(120987).update!(:width => 864, :height => 506)
      MediaItem.find(127765).update!(:width => 864, :height => 506)
      activity = copy_from_activity.clone
      activity.activity_type = "interactive_tutorial"
      activity.title = 'Example Interactive Tutorial'
      activity.cms_activity_id = 27
      activity.cms_revision_id = 40027
      activity.points_possible = 12

      input_file = File.join('db', 'example_data', "interactive_tutorial_content.xml")
      file_contents = File.read( input_file )
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_reference_activity(program_id)
      lesson = Program.find(program_id).units.first.lessons.first
      strand = lesson.strands.first
      copy_from_activity = strand.descendant_activities.first
      activity = copy_from_activity.clone
      activity.activity_type = "reference_activity"
      activity.title = 'Example Reference Activity'
      activity.cms_activity_id = 28
      activity.cms_revision_id = 40028
      activity.points_possible = 12

      media_list = [
        "0013/7761/VOL1e_L05.1_LEARN_feliz.mp3",
        "0013/7760/VOL1e_L05.1_LEARN_abierto.mp3",
        "0013/7759/VOL1e_L05.1_LEARN_abierta.mp3",
        "0013/7762/VOL1e_L05_VOC_estar_de_vacaciones.mp3",
        "0013/7762/VOL1e_L05_VOC_estar_de_vacaciones.mp3",
        "0000/0247/ICD-142B-1a.jpg",
        "0000/0248/ICD-142B-1b.jpg",
        "0000/0249/ICD-142B-1c.jpg",
        "0013/6303/AD2eB2_L04_recap_resumen.png",
        "0013/2864/AVE4e_L07.1_TXT_SIM_act3_p1.mp3",
      ]
      copy_media_from_cms(media_list)

      input_file = File.join('db', 'example_data', "reference_activity.xml")
      file_contents = File.read( input_file )
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def create_vocab_list_v2_activity(program_id)
      lesson = Program.find(program_id).units.first.lessons.first
      strand = lesson.strands[1]
      copy_from_activity = strand.descendant_activities.first
      activity = copy_from_activity.clone
      activity.activity_type = "vocab_list_v2"
      activity.title = 'Example Vocab List v2 Activity'
      activity.cms_activity_id = 31
      activity.cms_revision_id = 40031
      activity.points_possible = 12

      media_list = []
      copy_media_from_cms(media_list)

      input_file = File.join('db', 'example_data', "vocab_list_v2.xml")
      file_contents = File.read( input_file )
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "Location of activity xml: #{activity.content_filepath}"
    end

    def generate_video_thumbnails(program_id)

      FileUtils.mkdir_p("public/dashboard_thumbnails") unless File.exist?("public/dashboard_thumbnails")

      program = program = Program.find_by_id(program_id)
      lessons_ids = program.lessons
      video_activities = get_video_activities(program_id)
      video_activities.each do |video_activity|
        video_activity.create_dashboard_thumbnail
      end
    end

    def set_last_unit_as_not_released(program_id)
      program = Program.find_by_id(program_id)
      unit_to_unrelease = program.units.last
      unit_to_unrelease.update(released: false) if unit_to_unrelease.released?
    end

    def load_file_types_fixtures
      DemoData::Loader.new.load_file_types_data
    end

    def create_recordingv2_activity(activity_id)
      activity = Activity.find(activity_id)
      input_file = File.join('db', 'example_data', "recording_v2_content.xml")
      file_contents = File.read( input_file )
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.activity_type = "recording_v2"
      activity.save!
      puts "#{activity.title} created!"
    end

    def create_partner_chat_activity(program_id)
      # lesson = Program.find(program_id).units.first.lessons.first
      lesson = Program.find(program_id).units[3].lessons.first # fourth lesson for Ave
      strand = lesson.strands.first
      copy_from_activity = strand.descendant_activities.first

      activity = copy_from_activity.clone
      activity.activity_type = "partner_chat"
      activity.title = 'Típico fin de semana'
      activity.cms_activity_id = 29
      activity.cms_revision_id = 40029
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', "partner_chat_content.xml")
      file_contents = File.read( input_file )
      File.open( activity.content_filepath, 'w' ) { | file | file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
    end

    def create_cultural_notes_activity(program_id)
      unit_index = 0
      cms_activity_id = 30
      title = 'Notas culturales'
      source_filename = 'cutural_notes.xml'
      media_list = [
                    "0014/0316/el_morro.png",
                    "0014/0318/salsa.png",
                    "0014/0315/arecibo.png",
                    "0014/0317/relacion_con_los_eeuu.png"
                   ]


      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[2].children[0] # En Detaile substrand within Cultura strand
      copy_from_activity = strand.descendant_activities[1] # Cierto o Falso

      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = 'reference_activity'
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read(input_file)
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open( activity.content_filepath, 'w') { |file| file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "file path: #{activity.content_filepath}"
    end

    def create_adelante_explore_activity(program_id)
      unit_index = 0
      cms_activity_id = 36
      title = 'Adelante Explore Activity'
      source_filename = 'adelante_explore_activity.xml'
      media_list = [
                    "0014/2668/lectura.jpg",
                    "0014/2666/escritura.jpg",
                    "0014/2667/escuchar.jpg",
                    "0014/2665/en_pantalla.jpg",
                    "0014/2664/flash_cultura.jpg"
                   ]

      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[4].children.first # Lectura substrand within Adelante strand
      copy_from_activity = strand.descendant_activities[0] # Preguntas

      copy_media_from_cms(media_list)

      MediaItem.find([142668, 142666, 142667, 142665, 142664]).each do |media_item|
        media_item.update!(:width => 145, :height => 170)
      end

      activity = copy_from_activity.clone
      activity.activity_type = 'reference_activity'
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read(input_file)
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open(activity.content_filepath, 'w') { |file| file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "file path: #{activity.content_filepath}"
    end

    def create_mc_only_exam_activity(program_id)
      unit_index = 0
      cms_activity_id = 41
      title = 'Multiple Choice Exam'
      source_filename = 'all_mc_exam.xml'
      media_list = [
                    '0012/0249/VIS4e_L08_TXT_VEPI_w1.mp4',
                    '0011/1825/VIS4e_L08_TXT_LISTEN_2.mp3',
                    '0011/1962/VIS4e_L08.4_LM_1.mp3'
                   ]

      lesson = Program.find(program_id).units[unit_index].lessons.first
      strands = lesson.strands(true)
      strand = strands.detect { |strand| strand.assessment? }
      copy_from_activity = strand.descendant_activities[0]

      copy_media_from_cms(media_list)

      MediaItem.find([120249]).each do |media_item|
        media_item.update!(width: 350, height: 216)
      end

      activity = copy_from_activity.clone
      activity.activity_type = 'exam'
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read(input_file)
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open(activity.content_filepath, 'w') { |file| file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "file path: #{activity.content_filepath}"
    end

    def create_reading_preview_activity(program_id)
      unit_index = 0
      cms_activity_id = 40
      title = 'Reading Preview Activity'
      source_filename = 'reading_preview_activity.xml'
      media_list = [
              "0014/2586/iguacu.png",
              "0014/2705/VOL1e_L05_LEARN_CULT_p163_perfil_image1.jpg"
            ]

      lesson = Program.find(program_id).units[unit_index].lessons.first
      strand = lesson.strands[4].children.first # Lectura substrand within Adelante strand
      copy_from_activity = strand.descendant_activities[2] # Panorama: Estados Unidos Y Canadá

      copy_media_from_cms(media_list)

      activity = copy_from_activity.clone
      activity.activity_type = 'reference_activity'
      activity.title = title
      activity.cms_activity_id = cms_activity_id
      activity.cms_revision_id = 40000 + cms_activity_id
      activity.points_possible = 15

      input_file = File.join('db', 'example_data', 'xml', source_filename)
      file_contents = File.read(input_file)
      FileUtils.mkdir_p(File.dirname(activity.content_filepath))
      File.open(activity.content_filepath, 'w') { |file| file.puts file_contents }
      activity.save!
      puts "#{activity.title} created!"
      puts "file path: #{activity.content_filepath}"
    end

    def create_current_events_unit(program_id)
      program = Program.find(program_id)
      if program.current_events_unit
        puts "Program already has a current events unit."
        return
      end
      sample_unit = program.units.last
      sample_lesson = sample_unit.lessons.first
      new_toc_location = sample_unit.toc_location + 1
      unit_params = {
        'rank' => sample_unit.rank + 1,
        'name' => 'Current events',
        'label' => 'Current events',
        'media_item_id' => sample_unit.media_item_id,
        'released' => 1,
        'use_type' => 'CurrentEvents',
        'program_id' => program_id,
        'toc_location' => new_toc_location
      }
      UnitPublishProcessor.new(unit_params).process_request
      lesson_params = {
        'unit_toc_location' => new_toc_location,
        'rank' => 0,
        'name' => 'Current events',
        'label' => 'Current events',
        'toc_entries_xml' => sample_lesson.toc_entries_xml
      }
      LessonPublishProcessor.new(lesson_params).process_request
      current_events_unit = program.reload.current_events_unit
      current_events_lesson = current_events_unit.lessons.first
      puts "Current events unit has been created (id = #{current_events_unit.id}) " \
           "with its lesson (id = #{current_events_lesson.id})"
    end

    private

    def get_video_activities(program_id)
      video_activities = Activity.where(activity_type: 'video_v2',
                                        units: {program_id: program_id},
                                        readonly: false)
                                 .joins('INNER JOIN lessons ON activities.lesson_id = lessons.id INNER JOIN units ON lessons.unit_id = units.id')
                                 .all

    end

    def create_resource_unit_and_lesson(program_id)
      program = Program.find_by_id(program_id)
      @unit = Unit.find_or_create_by_name( :name => "No #{program.unit_label}", :rank => 99, :program_id => program_id, :label => "No #{program.unit_label}" )
      if @unit.use_type != "ResourceUnit"
        @unit.use_type = "ResourceUnit"
        @unit.save!
      end

      @lesson = Lesson.find_or_create_by_name("No #{program.unit_label}", :rank => 0, :unit_id => @unit.id)
      if @lesson.use_type != "ResourceLesson"
        @lesson.use_type = "ResourceLesson"
        @lesson.save!
      end
    end

    def unit_for_resource(unit_rank, program_id)
      unit = Unit.where(rank: unit_rank, program_id: program_id).first
      unit.id unless unit.nil?
    end

    def random_number(from, to)
      from + rand((to - from).abs)
    end

    def create_assignments_and_grades(section, students)
      create_assignment_data(section, @program.id)
      Enrollment.enroll_demo_students(students, section)
    end

    def create_closed_course
      puts "creating closed course and section for #{@instructor.username}"
      course_name = "#{@program.language_name} 101 (closed)"

      course = FactoryBot.create(:closed_course,
                                    owner:       @instructor,
                                    school:      @school,
                                    program_id:  @program.id,
                                    name:        course_name,
                                    start_date:  5.months.ago.monday,
                                    end_date:    2.months.ago,
                                    first_unit:  @program.units.first,
                                    last_unit:   @program.units.last
      )
      FactoryBot.create(:category,
                            course: course,
                            name: 'Practice',
                            weighting_percent: 50,
                            rank: 1,
                            max_attempts: 2)
      FactoryBot.create(:category,
                            course: course,
                            name: 'Exams',
                            weighting_percent: 50,
                            rank: 2,)
      create_section(course, class_days = '2,3,5', 'TWF - 10:00am')

      Maestro::CourseLicense.create(course.guid, course_packages(@program.id))

      course
    end

    def create_active_course
      puts "creating active course and sections for #{@instructor.username}"
      course_name = "#{@program.language_name} 101"

      course = FactoryBot.create(:course,
                                    owner:      @instructor,
                                    school:     @school,
                                    program_id: @program.id,
                                    name:       course_name,
                                    start_date: 4.weeks.ago.monday,
                                    end_date:   8.months.from_now,
                                    first_unit: @program.units.first,
                                    last_unit:  @program.units.last
      )

      create_standard_categories(course)

      create_section(course, class_days = '1,2,5', 'MTuF - 11:00am')
      create_section(course, class_days = '1,2,5', 'MTuF - 2:00pm')

      Maestro::CourseLicense.create( course.guid, course_packages(@program.id) )

      course
    end

    def create_section(course, class_days = '1,3,5', schedule = nil, name = nil)
      name ||= 'Section ' + (course.sections.count + 1).to_s

      section = FactoryBot.create(
        :section_without_section_instructor_callback,
        name: name,
        schedule: schedule || FactoryBot.generate(:schedule),
        instructor: course.owner,
        course: course,
        class_days: class_days,
        due_time: DateTime.civil(2011, 1, 1, 8, 0),
        section_instructors_attributes: {
          '0' => {
            user_id: course.owner.id,
            role: 'Instructor'
          }
        }
      )

      section
    end

    def create_standard_categories(course)
      FactoryBot.create(:category,
                            course: course, name: 'Practice',
                            weighting_percent: 10,
                            rank: 1,
                            max_attempts: 2,
                            credit_only: true)
      FactoryBot.create(:category,
                            course: course, name: 'Homework',
                            weighting_percent: 10,
                            rank: 2,
                            max_attempts: 2)
      FactoryBot.create(:category,
                            course: course, name: 'Lab',
                            weighting_percent: 15,
                            rank: 3,
                            max_attempts: 2)
      FactoryBot.create(:category,
                            course: course, name: 'Quizzes',
                            weighting_percent: 25,
                            rank: 4)
      FactoryBot.create(:category,
                            course: course,
                            name: 'Exams',
                            weighting_percent: 40,
                            rank: 5)

    end

    def make_gradebook_current
      puts "Making gradebook current for #{@instructor.username}..."
      updater = Gradebook::Updater.new(Time.zone.now)
      @instructor.courses.each { |course| updater.make_course_current(course) }
    end

    def create_announcements(instructor)
      instructor.courses.each do |course|
        focus = Focus.new(instructor, @program, {@program.id => {course_id: course.id}})
        announcement_params = {announcement: {
          author_id: instructor.id,
          title: 'Welcome to the course.',
          body: "Welcome to your course '#{course.name}' with professor '#{instructor.full_name}', hope you will enjoy it as much as I do teaching it."
        }}
        create_announcement(focus, instructor, announcement_params)

        if course.sections.any?
          focus = Focus.new(instructor, @program, {@program.id => {section_id: course.sections.first.id}})

          announcement_params = {announcement: {
            author_id: instructor.id,
            title: 'Pending assingments reminder.',
            body: "They are some activity assignments that require your attention, don't leave them all for the due date."
          }}
          create_announcement(focus, instructor, announcement_params)

          announcement_params = {announcement: {
            author_id: instructor.id,
            title: 'Happy holidays!!',
            body: "Remember that next January 1st it's a holiday, we will start classes on January 4th. Happy holidays."
          }}
          create_announcement(focus, instructor, announcement_params)
        end
      end
    end

    def create_announcement(focus, instructor, announcement_params)
      create_params = set_announcement_params(focus, instructor, announcement_params)
      instructor.announcements.create(create_params)
    end
    private :create_announcement

    def set_announcement_params(focus, instructor, params)
      params[:announcement].merge({ announcement_sections_attributes:
                                      ::AnnouncementSection::AnnouncementSectionsAttributesBuilder.build(focus, instructor, nil) })
    end
    private :set_announcement_params
  end
end

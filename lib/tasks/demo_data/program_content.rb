require 'fileutils'
require 'tasks/demo_data/fix_program/concept_colors'

module DemoData
  module ProgramContent
    # updates various attributes of the program
    # that the cms does not handle yet

    PUBLIC_HOME = File.join('./', 'public')
    DATAFILES_HOME = File.join('datafiles', Rails.env)
    EXAMPLE_XML_DIR = File.join('db', 'example_data', 'xml')

    def update_program_data(program_id)
      update_lesson_labels(program_id)
      update_program_image(program_id)
      set_program_banner_image(program_id)
      set_concept_colors(program_id)
      update_assessment_activities(program_id)
    end

    def create_content_for_program_with_units_and_lessons(program_id, program_name, unit_label, lesson_label)
      puts "creating contents for two two-tier programs"

      unit_thumbnails = [115931, 115932, 115941, 115942, 115943, 115945, 115946, 115947, 115948,
                         115933, 115934, 115935, 115936, 115937, 115938, 115939, 115940]

      two_tier_program = Program.find(program_id)

      if two_tier_program
        8.times do |index|
          rank = index + 1
          title = "#{unit_label} #{rank}"
          FactoryBot.create(:unit_with_lessons_with_toc_entries,
                                name: title,
                                label: title,
                                program: two_tier_program,
                                rank: rank)
        end
        two_tier_program.lessons.each_with_index do |lesson, index|
          title = "#{lesson_label} #{(index + 1)}"
          lesson.update!(:name => title, :label => title)
          lesson.toc_entries.each do |toc_entry|
            concept = FactoryBot.create(:concept,
                                            lesson: lesson,
                                            program: two_tier_program,
                                            name: toc_entry.title)
            toc_entry.each_leaf do |strand|
              3.times do |activity_index|
                FactoryBot.create(:activity,
                                      lesson: lesson,
                                      toc_location: strand.location,
                                      concept: concept,
                                      toc_location_rank: activity_index + 1)
              end
            end
          end
        end

        two_tier_program.units.each_with_index do |unit, index|
          unit.media_item_id = unit_thumbnails[index % unit_thumbnails.length]
          unit.save!
        end
      end
    end

    def create_program_media_items
      Program.all.each do |program|
        media = MediaItem.new
        media.filename = File.basename(program.small_image_path)
        copy_from = File.join(PUBLIC_HOME, program.small_image_path)
        media.media_type = 'image'
        media.save!

        copy_to = File.join(PUBLIC_HOME, media.public_filename)
        DemoData::DataFile.copy(copy_from, copy_to)

        program_media_item = ProgramMediaItem.create!(:program => program , :media_item => media)
        program_media_item.media_type = 'logo'
        program_media_item.save!
      end

      # # set real banner image for vistas 4e
      copy_media_from_cms([["0011/8621/VIS4e_cvr_Maestro.png", {:width => 277, :height => 111}]])
      program_media_item = ProgramMediaItem.find_by(program_id: 50)
      program_media_item&.update!(media_item_id: 118621)
    end

    def load_lesson_toc_entries
      puts "starting  loading toc_entries xml for lessons"
      Program.all.each do |program|
        program.lessons.each do |lesson|
          filename = sprintf("m3_program-%02d_lesson-%02d.xml", program.id, lesson.rank)
          filepath = File.join(EXAMPLE_XML_DIR, filename)
          next unless File.exist?(filepath)
          lesson.toc_entries_xml = File.read(filepath)
          lesson.from_xml
          lesson.save!
        end
      end
      puts "completed loading toc_entries xml for lessons"
    end

    def import_activity_completion_times
      puts "STATUS: Calculating activity completion times...\n"

      input_file = File.join('db', 'example_data', 'activity_completion_time_inputs.csv')

      DemoData::CSV.rows(input_file) do |row|
        completion_minutes = calculate_completion_minutes(row[:component], row[:structure])
        raise "Didn't get integer for row #{row.inspect}" unless completion_minutes.is_a?(Fixnum) and completion_minutes > 0
        activity = Activity.find(row[:id])
        activity.minutes_to_complete = completion_minutes
        activity.save
      end
      puts "STATUS: Done calculating activity completion times...\n"
    end

    def build_placeholder_activities
      puts "STATUS: Writing placeholder activity xml files...\n"

      input_file = File.join('db', 'example_data', 'activity_direction_lines.csv')
      DemoData::CSV.rows(input_file) do |row|
        activity = Activity.find(row[:id])

        filepath = Activity.filepath_from_revision_id(activity.cms_revision_id)
        unless File.exist?(filepath)
          doc = Nokogiri::XML::Document.new
          root = Nokogiri::XML::Node.new('activity', doc)
          root.set_attribute("activity_type", 'fill_in_the_blanks')
          root.set_attribute("language", 'es')
          doc.root = root
          root['title'] = html_strip_and_decode(activity.title)

          dl = root.add_child(Nokogiri::XML::Node.new('dl', doc))
          dl.content = html_strip_and_decode(row[:direction_line_text])

          items = root.add_child(Nokogiri::XML::Node.new('items', doc))

          style = items.add_child(Nokogiri::XML::Node.new('style', doc))
            wol = style.add_child(Nokogiri::XML::Node.new('wol_size', doc))
            wol.content = 'sentence_long'

          item = items.add_child(Nokogiri::XML::Node.new('item', doc))
          prompt = item.add_child(Nokogiri::XML::Node.new('prompt', doc))
          prompt.add_child(Nokogiri::XML::Node.new('wol', doc))
          answers = item.add_child(Nokogiri::XML::Node.new('answers', doc))
          answer = answers.add_child(Nokogiri::XML::Node.new('answer', doc))
          answer.content = "Cevicheria Jhon's, la mejor paella de la ciudad."
          answer = answers.add_child(Nokogiri::XML::Node.new('answer', doc))
          answer.content = "Cevicheria Jhon's, la peor pasta de la ciudad."
          answer = answers.add_child(Nokogiri::XML::Node.new('answer', doc))
          answer.content = "Cevicheria Jhon's, comida de la mejor calidad y sabor."
          answer = answers.add_child(Nokogiri::XML::Node.new('answer', doc))
          answer.content = "Cevicheria Jhon's, ubicada en la ciudad de Boston."

          activity.content = doc.to_xml(:encoding => 'UTF-8', :indent => 2)
        end
      end
      puts "STATUS: Done writing placeholder activity xml files...\n"
    end

    private

    def cover_image_media_id(program)
      return 118621 if program.title.match(/vistas/i)
      return 119107 if program.title.match(/panorama/i)
    end

    def cms_image_path(program)
      return "0011/8621/VIS4e_cvr_Maestro.png" if program.title.match(/vistas/i)
      return "0011/9107/PAN4e_cvr_Maestro.png" if program.title.match(/panorama/i)
    end

    def set_concept_colors(program_id)
      program = Program.find_by_id(program_id)
      return if program.title.match(/panorama/i) || program_id.to_i == 47
      FixProgram::ConceptColors.new(program)
    end

    def set_program_banner_image(program_id)
      puts "setting program banner image"
      program = Program.find_by_id(program_id)
      cover_image_media_id = cover_image_media_id(program)
      cms_image_path = cms_image_path(program)

      copy_media_from_cms([[cms_image_path, {:width => 277, :height => 111}]])
      program_media_item = ProgramMediaItem.where(program_id: program_id, media_type: 'logo').first
      if program_media_item
        program_media_item.update!(:media_item_id => cover_image_media_id)
      else
        program_media_item = ProgramMediaItem.create!(:program_id => program_id, :media_item_id => cover_image_media_id)
        program_media_item.media_type = 'logo'
        program_media_item.save!
      end
    end

    def download_unit_thumbnails
      puts "downloading unit thumbnails"
      hotspot_image_path = "public/media_items/" + Rails.env + "/images/0010/00107344.jpg"
      FileUtils.rm(hotspot_image_path) if File.exist?(hotspot_image_path)
      copy_media_from_cms(["0010/7344/VIS4e_L01_TXT_CON_hotspot.jpg",
                           ["0011/5944/VIS3e_L06_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5941/VIS3e_L03_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5939/VIS3e_L17_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5947/VIS3e_L09_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5936/VIS3e_L14_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5943/VIS3e_L05_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5946/VIS3e_L08_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5937/VIS3e_L15_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5932/VIS3e_L02_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5933/VIS3e_L11_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5945/VIS3e_L07_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5940/VIS3e_L18_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5948/VIS3e_L10_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5938/VIS3e_L16_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5942/VIS3e_L04_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5931/VIS3e_L01_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5935/VIS3e_L13_TOC.PNG", {:width => 110, :height => 86}],
                           ["0011/5934/VIS3e_L12_TOC.PNG", {:width => 110, :height => 86}]])
    end

    def set_unit_thumbnails(program_id)
      unit_thumbnails = [115931, 115932, 115941, 115942, 115943, 115945, 115946, 115947, 115948, 115933, 115934, 115935,
                         115936, 115937, 115938, 115939, 115940]

      download_unit_thumbnails

      puts "associating unit thumbnails"
      Unit.where(program_id: program_id).each_with_index do |unit, index|
        unit.media_item_id = unit_thumbnails[index % unit_thumbnails.length]
        unit.save!
      end
    end

    def update_program_image(program_id)
      program = Program.find_by_id(program_id)
      program.update!(:image_filename => 'vistas4e.png') if program.title.match(/vistas/i)
      program.update!(:image_filename => 'panorama4e.png') if program.title.match(/panorama/i)
    end

    def update_lesson_labels(program_id)
      program = Program.find_by_id(program_id)
      program.lessons.each_with_index do |lesson, index|
        lesson.update!(:label => "Lección #{index+1}", :rank => index) if lesson.label.nil?
      end
    end

    def update_assessment_activities(program_id)
      program = Program.find_by_id(program_id)
      return if program.title.match(/panorama/i) || program_id.to_i == 47
      program.lessons.each do |lesson|
        # recapitulacion strand
        diagnostic_concept = lesson.concepts.detect{ |concept| concept.name =~ /^recapitulacion$/ }
        diagnostic_strand = lesson.toc_entries.detect{ |strand| strand.title =~ /^recapitulacion$/ }
        if diagnostic_concept
          diagnostic_concept.name = "recapitulación"
          diagnostic_concept.breadcrumb_string = "recapitulación"
          diagnostic_concept.save!
        else
          diagnostic_concept = create_or_find_concept("recapitulación", lesson, program, "#606060")
        end
        if diagnostic_strand
          diagnostic_strand.title = "recapitulación"
          lesson.save!
        else
          diagnostic_strand = create_or_find_strand("recapitulación", lesson, program, diagnostic_concept.id, "#606060")
        end
        # vocabulario quiz strand
        vocabulary_quiz_concept = create_or_find_concept("Vocabulary Quiz", lesson, program, "#606060", true)
        vocabulary_quiz_strand = create_or_find_strand("Vocabulary Quizzes", lesson, program, vocabulary_quiz_concept.id, "#606060", true)
        # grammar quiz strand
        grammar_quiz_concept = create_or_find_concept("Grammar Quiz", lesson, program, "#606060", true)
        grammar_quiz_strand = create_or_find_strand("Grammar Quizzes", lesson, program, grammar_quiz_concept.id, "#606060", true)
        # lesson tests strand
        lesson_tests_concept = create_or_find_concept("Lesson Test", lesson, program, "#606060", true)
        lesson_tests_strand = create_or_find_strand("Lesson Tests", lesson, program, lesson_tests_concept.id, "#606060", true)
        # multi-lesson exams strand
        multi_lesson_exam_concept = create_or_find_concept("Multi-Lesson Exam", lesson, program, "#606060", true)
        multi_lesson_exam_strand = create_or_find_strand("Multi-Lesson Exams", lesson, program, multi_lesson_exam_concept.id, "#606060", true)

        recapitulacion_activities = lesson.activities.select{|activity| activity.title =~ /^Recapitulaci..|^Prueba de pr.ctica|^Prueba oral/}
        vocabulary_quiz_activities = lesson.activities.select{|activity| activity.title =~ /^Contextos.*Miniprueba/}
        grammar_quiz_activities = lesson.activities.select{|activity| activity.title =~ /^Estructura.*Miniprueba/}
        lesson_test_activities = lesson.activities.select{|activity| activity.title =~ /^Lecci.n.*Prueba/}
        exam_activities = lesson.activities.select{|activity| activity.title =~ /^Examen/}

        update_activites_toc_location(recapitulacion_activities, diagnostic_concept)
        update_activites_toc_location(vocabulary_quiz_activities, vocabulary_quiz_concept)
        update_activites_toc_location(grammar_quiz_activities, grammar_quiz_concept)
        update_activites_toc_location(lesson_test_activities, lesson_tests_concept)
        update_activites_toc_location(exam_activities, multi_lesson_exam_concept)
        update_strand_singular_label(vocabulary_quiz_strand, lesson, 'quiz')
        update_strand_singular_label(grammar_quiz_strand, lesson, 'quiz')
        update_strand_singular_label(lesson_tests_strand, lesson, 'test')
      end
    end

    def process_concept(lesson, concept, base_name, assessment)
      if concept.name =~ /^Lesson .: /
        concept.name = base_name
        concept.breadcrumb_string = base_name
        concept.save!
      end
    end

    def create_or_find_concept(concept_name, lesson, program, color, assessment = false)
      concept_name_plural = concept_name.pluralize
      requested_concept = lesson.concepts.detect do |concept|
        concept.name =~ /#{concept_name}$/
      end

      requested_concept ||= lesson.concepts.detect do |concept|
        concept.name =~ /#{concept_name_plural}$/
      end

      requested_concept&.update!(
        name: concept_name,
        breadcrumb_string: concept_name
      )

      if requested_concept && assessment && !requested_concept.assessment
        requested_concept.update!(
          assessment: assessment
        )
      end

      requested_concept ||= FactoryBot.create(
        :concept,
        lesson: lesson,
        program: program,
        name: concept_name,
        breadcrumb_string: concept_name,
        background_color: color,
        assessment: assessment
      )

      process_concept(lesson, requested_concept, concept_name, assessment)

      requested_concept.update!(:background_color => color)
      requested_concept
    end

    def create_or_find_strand(title, lesson, program, location, color, assesment_strand = false)
      #first remove the strands that have the same name bu in singular
      strand_to_remove = lesson.toc_entries.detect{ |strand| strand.title == title.singularize }
      lesson.toc_entries.delete( strand_to_remove ) if strand_to_remove

      requested_strand = lesson.toc_entries.detect{ |strand| strand.title == title }
      unless requested_strand
        requested_strand = TocEntry.new
        requested_strand.title = title
        requested_strand.location = location
        requested_strand.level = 1
        requested_strand.background_color = color
        requested_strand.assessment = assesment_strand
        lesson.toc_entries << requested_strand
        lesson.save!
      else
        if requested_strand.location != location
          requested_strand.location = location
          lesson.save!
        end
      end
      requested_strand
    end

    def update_activites_toc_location(activities, new_location)
      activities.each do |activity|
        next if activity.toc_location == new_location.id && activity.concept == new_location

        activity.update!(
          toc_location: new_location.id,
          concept: new_location
        )
      end
    end

    def update_strand_singular_label(strand, lesson, singular_label)
      strand.singular_label = singular_label
      lesson.save!
    end

    def calculate_completion_minutes(component, structure = '')
      default_completion_minutes = 6
      return default_completion_minutes if structure.blank?
      question_type_counts = Hash.new()

      question_sets = structure.split('|')
      question_sets.each do |question_set|

        qs_fields = question_set.split(',')
        question_type = qs_fields[0]
        question_count = qs_fields[1].to_i

        if question_type_counts[question_type]
          question_type_counts[question_type] = question_type_counts[question_type] + question_count
        else
          question_type_counts[question_type] = question_count
        end
      end

      total_seconds = 0
      question_type_counts.each_pair do |question_type, count|
        seconds_per_question = seconds_by_type(question_type, component)
        total_seconds += count * seconds_per_question
      end
      (total_seconds / 60).ceil
    end

    def seconds_by_type(question_type, component)
      case question_type
      when 'DS' then question_type = 'MC'
      when 'FB' then question_type = 'FBSent'
      when 'RC' then question_type = 'OE'
      when 'MC','OE','FBSent','FBWord' then
      else
        raise "Unsupported question type #{question_type.inspect}"
      end

      @time_hash ||= {'MC' => {'SS' => 31.500,
                               'WB' => 30.333,
                               'LM' => 27.500,
                               'VM' => 32.597,
                              },
                  'FBWord' => {'SS' => 40.375,
                               'WB' => 41.500,
                               'LM' => 39.713,
                               'VM' => 51.700,
                              },
                  'FBSent' => {'SS' => 64.313,
                               'WB' => 68.520,
                               'LM' => 84.529,
                               'VM' => 99.690,
                              },
                      'OE' => {'SS' => 88.787,
                               'WB' => 89.000,
                               'LM' => 79.267,
                               'VM' => 97.633,
                              },
                        }
      @time_hash[question_type][component]
    end

  end
end

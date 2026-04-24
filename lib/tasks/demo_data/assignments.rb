# encoding: utf-8
module DemoData
  module Assignments
    # assign first 3 activities in each strand/component,
    # increasing the due date by 2 days each strand
    @@due_date = nil
    @@assignment_rank = 0
    @@assign_per_location = 1
    @@assignment_gap = 4.weeks
    @@skipped_gap = false
    @@categories = Hash.new
    @@future_assessments_to_assign = 1

    def create_assignment_data(section, program_id, is_closed = false)
      @@due_date = nil  # reset to nil to start
      @@skipped_gap = false
      puts "starting to create assignments for section #{section.name} in course #{section.course.name}"
      assignable_components = ["Activities", "Analyse", "Animated Grammar Tutorials",
                               "Assessment", "Build Your Skills: À l'écoute",
                               "Build Your Skills: Écriture", "Build Your Skills: En pantalla",
                               "Build Your Skills: Escritura", "Build Your Skills: Escuchar",
                               "Build Your Skills: Flash cultura", "Build Your Skills: Flash culture",
                               "Build Your Skills: Le Zapping", "Build Your Skills: Lectura",
                               "Build Your Skills: Lecture", "Build Your Skills: Listen",
                               "Build Your Skills: Read", "Build Your Skills: Watch",
                               "Cahier de l'élève", "Cahier de l'élève: Audio Activities",
                               "Cahier de l'élève: Video Activities", "Cahier virtuel",
                               "Communicate", "Communication", "Communication Activities",
                               "composition,textbook", "Comprehension", "Comprehension Activities",
                               "Cuaderno de actividades comunicativas", "Cuaderno de práctica",
                               "Explore", "For heritage speakers", "Games", "Instructions",
                               "Instructor-created Activities", "Lab Manual", "Learn",
                               "Manual de gramática: Más práctica", "Mira la película",
                               "Mise en pratique", "Optional Testing Items", "Piénsalo", "Práctica",
                               "Práctica y escritura", "Practice", "Practice Activities",
                               "Practice and Communication", "Practice and Communication Activities",
                               "Practice Test", "Prepárate", "Préparation", "Preparation Activities",
                               "Presentación", "Présentation", "Presentations",
                               "Presentations and Tutorials", "Quizzes", "Selections", "Self-check",
                               "Test de pratique", "Tutorials", "Unlisted", "Video Manual", "Workbook"
                               ]
      next_due_date(section)

      program = Program.find(program_id)
      program.lessons[0..4].each do |lesson|
        strand_count = 0
        lesson.toc_entries.each do |toc_entry|
          # looping thru child nodes for a lesson
          assigned = false
          if toc_entry.assessment?
            process_assessment_assignments(toc_entry, section) unless toc_entry.location.blank?
          else          #puts "----------- #{toc_entry.title} #{@@due_date} - #{strand_count} ------------------"
            toc_entry.each do |toc_node|
              next if toc_node.location.nil?
              #looping thru child nodes for each strand/substrand
              activity_ids = Services::TocActivityList.all_for_toc_location(toc_node.location).values.flatten
              activities = Activity.where(id: activity_ids)

              assignable_components.each do |component_name|
                activities_in_component = activities.select {|activity| component_name == activity.component_name}
                unless activities_in_component.empty?
                  #puts "** creating assignments for Node #{toc_node.title} component #{component_name} ..."
                  activities_to_assign = (is_closed ? [activities_in_component.last] : select_activities(activities_in_component, @@assign_per_location))
                  activities_to_assign.each do |activity|
                    create_assignment(section, activity)
                    assigned = true
                  end
                end
              end
            end
            strand_count += 1 if assigned
            next_due_date(section) if (strand_count % 2 == 0)
          end
        end
        #next_due_date unless (strand_count % 2 == 0)
      end
    end

    def select_activities(activities, num)
      selection = []
      selection << activities.select { |activity| activity.instructor_graded? }.first
      selection.to_a.compact!
      num -= selection.count
      selection << activities[0..num-1] if num > 0
      selection.flatten
    end

    def process_assessment_assignments(toc_entry, section)
      activity_ids = Services::TocActivityList.all_for_toc_location(toc_entry.location).values.flatten
      activities = Activity.where(id: activity_ids)
      activity = activities.first

      return if activity.blank?

      if @@due_date > Date.today
        if @@future_assessments_to_assign > 0
          create_assignment(section, activity)
          @@future_assessments_to_assign -= 1
        end
      else
        create_assignment(section, activity)
      end
      next_due_date(section)
    end

    def next_due_date(section)
      @@due_date ||= section.course.start_date
      @@skipped_gap ||= false
      next_day = next_class_day(section, @@due_date)
      if @@due_date.wday > next_day
        @@due_date = (Week.week_containing(@@due_date.next_week) + next_day.days).to_date
      else
        @@due_date = (Week.week_containing(@@due_date) + next_day.days).to_date
      end
      if @@due_date > section.course.end_date
         @@due_date = section.course.end_date.clone
      end
      if @@due_date > Date.today && !@@skipped_gap
        @@due_date += 4.weeks
        @@skipped_gap = true
      end
      #puts "Next due date: #{@@due_date.wday} - #{@@due_date} (#{@@due_date.class})"
    end

    def next_class_day(section, due_date)
      #puts "class days: #{section.class_days}"
      days = section.class_days.split(',')
      if due_date.nil?
        day = days[0]
      else
        day = days.select { |d| due_date.wday < d.to_i }.first
        day = days[0] unless day
      end
      day.to_i
    end

    def component_to_category(course, activity)
      @@categories[course.id] ||= Category.where(course_id: course.id)
      retval = @@categories[course.id].detect {|category| category.name == 'Quizzes'}  if ['Assessment'].include?(activity.component_name) && activity.title.match(/prueba de/i) && activity.assessment?
      retval = @@categories[course.id].detect {|category| category.name == 'Exams'}    if ['Assessment'].include?(activity.component_name) && activity.assessment?
      retval = @@categories[course.id].detect {|category| category.name == 'Practice'} if ['Tutorials', 'Presentations and Tutorials', 'Practice Activities', 'Web-only Practice', 'Textbook Practice'].include?(activity.component_name)
      retval = @@categories[course.id].detect {|category| category.name == 'Homework'} if ['Workbook'].include?(activity.component_name)
      retval = @@categories[course.id].detect {|category| category.name == 'Lab'} if ['Lab Manual', 'Video Manual'].include?(activity.component_name)
      retval = @@categories[course.id].detect {|category| category.name == 'Homework'}  if activity.title.match(/recapitulac/i)

      retval = @@categories[course.id].detect {|category| category.name == 'Practice'} if retval.nil?
      retval
    end

    def create_assignment(section, activity)
      params = {
        :assignable_id => activity.id,
        :assignable_type => 'Activity',
        :due_date => @@due_date,
        :section_id => section.id,
        :created_at => Time.now,
        :updated_at => Time.now,
        :rank => @@assignment_rank,
        :category_id => component_to_category(section.course, activity).id,
        :current => 0,
        :show_assessment => 'a specific date and time',
        :show_at => "#{(@@due_date-1.day)} 00:00:00"
      }
      @@assignment_rank += 1
      FactoryBot.create(:assignment, params)
    end
  end
end

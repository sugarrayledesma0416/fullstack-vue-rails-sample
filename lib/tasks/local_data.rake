
namespace :local_data do
  desc "clean out course related data"
  task :remove_all_course_data => :environment do |task|
    raise "DO NOT RUN on Live server!!!" if Rails.env.live?

    puts <<-WARNING_MSG.strip_heredoc
      Removes all course related data from your local database.
      Tables affected:
        assignments
        courses (archived)
        sections (archived)
        section_instructors
        enrollments (archived)
        categories
        attempts
        scoring_rulesets
        feedback_items

    Do you want to proceed (y/N)?"
    WARNING_MSG
    response = STDIN.gets.chomp.downcase

    if response == 'y'
      Dangerfield::Gatekeeper.instance.disabled = false
      puts "
        Cleanup started..."
        remove_all_course_data
        delete_activity_submission_data
      puts "
        Cleanup complete!"

      puts <<-WARNING_MSG.strip_heredoc
        To generate course data for an instructor and program, run:

          rake demo_data:create_instructor_data_set program_id=<id> instructor_id=<id>

        The instructor you use will determine the students that are enrolled. e.g.
          vhl_instructor will have vhl_student_1, vhl_student_2, etc. enrolled. If your
          student usernames are in the form vhl_vol_student_1, then a third param is required:

          rake demo_data:create_instructor_data_set program_id=<id> instructor_id=<id> short_program_name=vol"
      WARNING_MSG
      Dangerfield::Gatekeeper.instance.disabled = true
    else
      puts "
        Aborting..."
    end
  end

  def remove_all_course_data
    Course.all.each do |course|
      puts "
            Course ##{course.id} #{course.name}"

      course.sections.each do |section|
        puts "
              Section ##{section.id} #{section.name}"

        section.archive # archives the section, any enrollment records
                        # and section_instructors records
      end

      # archives the course and its categories
      course.archive
    end
    # a little further cleanup
    Category.delete_all
    SectionInstructor.delete_all
    ScoringRuleset.delete_all
  end

  def delete_activity_submission_data
    [Assignment, Attempt, FeedbackItem].each do |model|
      puts "
            Clearing #{model}..."
      model.delete_all
    end
  end
end

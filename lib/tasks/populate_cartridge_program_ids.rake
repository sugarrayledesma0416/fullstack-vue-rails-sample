namespace :cartridge do
  desc 'Populate the program attribute in the cartridge_course_context_details table'
  task populate_program_ids: :environment do |task_name|
    dry_run = ENV['dry_run']&.downcase == 'true'

    if %w[true false].exclude?(ENV['dry_run']&.downcase)
      puts "usage: #{task_name} dry_run=true|false"
      exit 1
    end

    ccds = Cartridge::CourseContextDetail.where(program_id: nil).includes(:course)
    count = 0
    ccds.each do |ccd|
      count = count + 1
      if !dry_run
        ccd.update_column(:program_id, ccd.course.program.id)
      else
        puts "Dry run CourseContextDetail context_id: #{ccd.lms_context_id} course id: #{ccd.course_id} program id: #{ccd.course.program.id}"
      end
    rescue StandardError=> e
      puts "CourseContextDetail id: #{ccd.id} failed to save program id: #{ccd.course.program.id}; error: #{e})"
    end
    puts "Added program id to #{count} courses"
  end
end

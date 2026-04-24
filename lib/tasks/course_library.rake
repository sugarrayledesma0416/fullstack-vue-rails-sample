namespace :course_library do

  desc "Creates a library for courses that do not have one"
  task :create_library_for_program_courses => :environment do |task|
    if ENV['program_id'].blank?
      puts "usage: rake #{task} program_id=<id>"
      exit
    end
    program_id = ENV['program_id']
    courses_without_library = Course.joins("LEFT JOIN course_library_activities ON course_libary_activities.course_id = courses.id").
                                where("course_liibrary_activities.id is null AND courses.program_id = ?", program_id)
    activities_ids = Program.find(program_id).activities(nil).pluck(:id)
    create_library_for_course(course, activities_ids)
    puts "#{courses_without_library.size} did not have an activity library, they have it now."
  end

  desc "Creates a library for a courses that do not have one"
  task :create_library_for_course => :environment do |task|
    if ENV['course_id'].blank?
      puts "usage: rake #{task} course_id=<id>"
      exit
    end
    course_without_library = Course.joins("LEFT JOIN course_library_activities ON course_library_activities.course_id = courses.id").
                                where("course_library_activities.id is null AND courses.id = ?", ENV['course_id']).first
    unless course_without_library
      puts "Course with ID: #{ENV['course_id']} was not found or already has a course library"
      exit
    end
    activities_ids = Program.find(course_without_library.program_id).activities(nil).pluck(:id)
    create_library_for_course(course_without_library, activities_ids)
    puts "Course with ID #{course_without_library.id} now has an activities library."
  end

  def create_library_for_course(course, activities_ids)
    ActiveRecord::Base.transaction do
      CourseActivity.import([:activity_id, :course_id], activities_ids.inject([]){ |data, activity_id| data << [activity_id, course.id]; data })
    end
  end
end

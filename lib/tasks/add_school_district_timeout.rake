desc 'Adds student & instructor timeout for schools and district.'
task add_school_district_timeout: :environment do |task_name|
  puts "usage: rake #{task_name} institute=<id> instructor_timeout=<timeout(in secs)>" \
       'student_timeout=<timeout(in secs)>'
  school = School.find_by(id: ENV['institute'].to_i)
  create_or_update_config(school)
  raise 'Pass institute id' unless ENV['institute']
end

private def create_or_update_config(institute)
  institute_config = institute.school_config
  institute_config ? update_config(institute_config) : create_config(institute)
end

private def update_config(institute_config)
  institute_config.update!(
    instructor_timeout: ENV.fetch('instructor_timeout').to_i,
    student_timeout: ENV.fetch('student_timeout').to_i,
    timeout_enabled: true
  )
  puts "Setting Record for school / district #{institute_config.id} is updated."
end

private def create_config(institute)
  SchoolConfig.create!(
    instructor_timeout: ENV.fetch('instructor_timeout'),
    student_timeout: ENV.fetch('student_timeout'),
    timeout_enabled: true,
    school_id: institute.id
  )
  puts "Setting Record is created for the school / district - #{institute.id}"
end

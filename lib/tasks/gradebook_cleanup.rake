namespace :gradebook_v2 do
  desc 'delete scores for courses that have been closed for more than 2 years'
  task :delete_old_scores => :environment do |task|
    delete_date = Date.today - 2.years
    course_ids = GradebookEngine::Course.where("end_date <= ?", delete_date).order(id: :asc).pluck(:id)
    puts "deleting scores for #{course_ids.length} courses closed on or before #{delete_date}"
    total_time = 0.0
    fastest_time = 999999.0
    slowest_time = 0.0
    course_ids.each_with_index do |course_id, i|
      print "deleting course #{course_id}... "
      start_time = Time.now
      GradebookEngine::GradebookAPI.delete_scores(course_id)
      elapsed_time = Time.now - start_time
      total_time += elapsed_time
      fastest_time = [elapsed_time, fastest_time].min
      slowest_time = [elapsed_time, slowest_time].max
      progress = ((i.to_f / course_ids.length) * 100).round
      puts "done in #{elapsed_time.round(2)} seconds (#{progress}%)"
    end
    average_time = total_time / course_ids.length
    puts "successfully deleted scores for #{course_ids.length} courses"
    puts "average course deletion time: #{average_time.round(2)}"
    puts "fastest course deletion time: #{fastest_time.round(2)}"
    puts "slowest course deletion time: #{slowest_time.round(2)}"
  end

  desc 'delete non-current score actions for courses that have been closed for more than 1 year'
  task :prune_old_scores => :environment do |task|
    delete_date_max = Date.today - 1.years
    delete_date_min = Date.today - 2.years
    course_ids = GradebookEngine::Course.where("end_date > ? AND end_date <= ?",
                                               delete_date_min, delete_date_max)
                   .order(id: :asc).pluck(:id)
    puts "pruning scores for #{course_ids.length} courses closed on or before #{delete_date_max}"
    total_time = 0.0
    fastest_time = 999999.0
    slowest_time = 0.0
    course_ids.each_with_index do |course_id, i|
      print "pruning course #{course_id}... "
      start_time = Time.now
      GradebookEngine::GradebookAPI.prune_scores(course_id)
      elapsed_time = Time.now - start_time
      total_time += elapsed_time
      fastest_time = [elapsed_time, fastest_time].min
      slowest_time = [elapsed_time, slowest_time].max
      progress = ((i.to_f / course_ids.length) * 100).round
      puts "done in #{elapsed_time.round(2)} seconds (#{progress}%)"
    end
    average_time = total_time / course_ids.length
    puts "successfully pruned scores for #{course_ids.length} courses"
    puts "average course deletion time: #{average_time.round(2)}"
    puts "fastest course deletion time: #{fastest_time.round(2)}"
    puts "slowest course deletion time: #{slowest_time.round(2)}"
  end
end

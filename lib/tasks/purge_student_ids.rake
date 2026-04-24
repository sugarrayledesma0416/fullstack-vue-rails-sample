desc 'Purge student_id values 1000 at a time until all are NULL.'

task purge_student_ids: :environment do
  puts 'Checking User database'

  id_condition = 'student_id is not null'

  # Use .unscoped so we null out values for archived users as well.
  user_scope = User.unscoped.where(id_condition)

  unless user_scope.exists?
    puts "no users where #{id_condition}"
    exit(0)
  end

  fixed_user_count = 0
  user_count_to_fix = user_scope.count
  puts "found #{user_count_to_fix} users where #{id_condition}"

  batch_size = 1000
  batch_count = (user_count_to_fix / batch_size) + 1

  batch_count.times do |index|
    puts "round #{index} of #{batch_count}"

    user_scope.limit(batch_size).update_all(student_id: nil)
    fixed_user_count += batch_size

    percent_remaining = (1 - (fixed_user_count / user_count_to_fix.to_f)) * 100
    puts "#{percent_remaining.round}% remains"
    puts "#{fixed_user_count} non null of #{user_count_to_fix} users"
  end
end


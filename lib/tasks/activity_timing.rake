namespace :activities do

  desc "Apply activity timings for activity types"
  task apply_time_estimates: :environment do |cmd_name|
    timings = ActivityTimeEstimateSetter.estimates
    standard_types = timings[0]['base']

    standard_types.keys.each do |type|
      time_estimate = standard_types[type]
      puts "setting #{type} to #{time_estimate} minutes."

      Activity.where(activity_type: type)
              .where('toc_location is not null AND lesson_id is not null')
              .find_each(batch_size: 1000) do |activity|
        setter = ActivityTimeEstimateSetter.new(
                   activity: activity,
                   estimates: timings
                 )
        if setter.needs_update?
          setter.update
          print '+'
        else
          print '-'
        end
      end
      puts '.'
    end
  end
end

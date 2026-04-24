require_relative '../../../app/models/learning_track/base'

module LearningTrack
  class GroupSetGenerator < Base
    def filename
      file_path("group_set_#{program.id}.csv")
    end

    def write_csv
      group_names = [
        'Explore',
        'Learn',
        'Practice',
        'Communicate',
        'Self-check',
        'Build Your Skills',
        'Build Your Skills: Read',
        'Build Your Skills: Write',
        'Build Your Skills: Listen',
        'Build Your Skills: Watch',
        'Assessment'
      ]
      csv_string = CSV.generate do |csv|
        csv << ['Group Set Name', "Learn Groups", nil, nil, nil, nil]
        csv << ['Lesson', 'Strand', 'Lesson Id', 'Strand Id', 'Group', 'Learning Objective', 'How To Use']
        program.lessons.each do |lesson|
          lesson.concepts.each do |concept|
            group_names.each do |group_name|
              csv << [lesson.label, concept.name, lesson.id, concept.id, group_name, "Objective for #{group_name}", "How to Use for #{group_name}"]
            end
          end
        end
      end
      s3_bucket.store_file_contents!(filename, csv_string)
    end
  end
end

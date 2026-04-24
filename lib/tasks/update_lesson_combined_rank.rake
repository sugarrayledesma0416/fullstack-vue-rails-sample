namespace :concept do
  desc 'update lesson_combined_rank in m3 when this have been published before add column'
  task update_lesson_combined_rank: :environment do |_cmd_name|
    Unit.find_in_batches(batch_size: 100) do |units|
      units.each do |unit|
        unit.lessons.each do |lesson|
          lesson.concepts.each do |concept|
            next unless concept.lesson_combined_rank == 0

            lesson_combined_rank = (unit.rank * 100 + lesson.rank + 1)

            concept.update!(lesson_combined_rank: lesson_combined_rank)
          end
        end
      end
    end
  end
end

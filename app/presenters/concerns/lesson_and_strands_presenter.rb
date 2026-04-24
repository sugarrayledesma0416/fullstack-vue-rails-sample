module LessonAndStrandsPresenter
  def lessons
    program.lessons.pluck(:id, :label).map { |id, label| { id: id, label: label } }
  end

  def strands_by_lesson
    program.lessons.flat_map do |lesson|
      lesson.strands.map do |strand|
        { lesson_id: lesson.id, title: strand.title, strand_id: strand.location }
      end
    end
  end
end

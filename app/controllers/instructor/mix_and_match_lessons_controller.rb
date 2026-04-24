class Instructor::MixAndMatchLessonsController < ApplicationController
  def index
    result = program.units.map do |unit|
      lessons = unit.lessons.to_a
      {
        id: unit.id,
        name: unit.display_name,
        is_multi_lesson: (lessons.size > 1),
        lessons: lessons.map do |lesson|
          {
            displayName: lesson.display_name,
            id: lesson.id,
            name: lesson.name
          }
        end
      }
    end
    render json: result.to_json
  end
end

# Creates assignments in the gradebook for each given section.

class BulkGbAssignmentCreator
  attr_reader :course, :sections, :categories

  def initialize(course, sections, categories)
    @course = course
    @sections = sections
    @categories = categories
  end

  def builder
    @assignment_builder ||= AssignmentBuilder.new
  end

  def categories
    @categories
  end

  def activities
    @activities ||= Activity.select('activities.id, activities.lesson_id, activities.concept_id')
                     .joins(:concept)
                     .where(concepts: { program_id: @course.program_id })
                     .index_by(&:id)
  end

  def activity_calendar(raw_assignments)
    builder.build_assignments(categories, raw_assignments)
  end

  def create(raw_assignments)
    # if an assignment with the same section id and activity id is encountered,
    # update the updated_at value - this mirrors what happens to the M3 assignment
    GradebookEngine::Assignment.import(column_names, column_values(raw_assignments), on_duplicate_key_ignore: true)
  end

  private def column_names
    %i[
      day_id
      week_id
      section_id
      activity_id
      category_id
      lesson_id
      strand_id
      individually_assignable
    ]
  end

  private def column_values(raw_assignments)
    activity_calendar(raw_assignments).map do |assignment|
      sections.map do |section|
        activity = activities.values_at(assignment[:activity_id].to_i).first
        assignment_attributes(
          assignment[:due_date],
          section.id,
          activity.id,
          assignment[:category],
          activity.lesson_id,
          activity.concept_id,
          assignment[:individually_assignable]
        )
      end
    end.flatten(1)
  end

  private def assignment_attributes(
    due_date,
    section_id,
    activity_id,
    category,
    lesson_id,
    concept_id,
    individually_assignable
  )
    [
      Time.parse(due_date),
      ::Week.week_containing(due_date),
      section_id,
      activity_id,
      category.id,
      lesson_id,
      concept_id,
      individually_assignable
    ]
  end
end

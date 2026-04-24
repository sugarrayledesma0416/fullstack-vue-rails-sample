describe GbAssignmentMigrator do
  include CourseBuilder

  let!(:unit) { create(:unit_with_lessons, program: create(:program)) }
  let!(:course) do
    create_course_with_stubs(
      first_unit: unit,
      last_unit: unit,
      program: unit.program
    )
  end
  let(:category) do
    create(:category, course_id: course.id, weighting_percent: 100)
  end
  let!(:section) { create(:section, course: course) }
  let(:lesson) { unit.lessons.first }
  let(:concept) { create(:concept, lesson: lesson) }
  let(:activity) do
    create(
      :activity,
      concept: concept,
      lesson: lesson
    )
  end

  # set due_date to ensure it falls within the course start and end dates
  # so that M3 assignment does not fail validation on save
  let(:m3_assignment) do
    create(
      :assignment,
      assignable: activity,
      assignable_type: 'Activity',
      category: category,
      due_date: section.course.end_date - 2.months,
      section: section
    )
  end
  let(:add_update_params) do
    {
      action: 'add_update',
      id: m3_assignment.id,
      model_name: 'Assignment'
    }
  end

  describe 'add_update model action' do
    it 'creates a new gradebook assignment record if it does not exist' do
      create(:gb_category, id: m3_assignment.category_id)
      create(:gb_section, id: section.id)
      create(:gb_strand, id: concept.id)
      create(:gb_lesson, id: lesson.id)
      create(
        :gb_activity,
        id: activity.id,
        lesson_id: lesson.id,
        strand_id: concept.id
      )
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy

      new_gb_assignment = ::GradebookEngine::Assignment.where(
        activity_id: m3_assignment.assignable_id,
        section_id: m3_assignment.section_id
      ).first
      expect(new_gb_assignment.category_id).to eql(m3_assignment.category_id)
      expect(new_gb_assignment.lesson_id).to eql(m3_assignment.assignable.lesson_id)
      expect(new_gb_assignment.strand_id).to eql(m3_assignment.assignable.concept_id)
      expect(new_gb_assignment.day_id).to eql(m3_assignment.due_date)
      expect(new_gb_assignment.week_id).to eql(::Week.week_containing(m3_assignment.due_date))
      expect(new_gb_assignment.school_id).to eq(m3_assignment.section.course.school_id)
    end

    it 'updates existing gradebook Assignment record', new_gb_sync: true do
      gb_assignment = ::GradebookEngine::Assignment.where(
        activity_id: m3_assignment.assignable_id,
        section_id: m3_assignment.section_id
      ).first
      expect(gb_assignment.day_id).to eql(m3_assignment.due_date)
      expect(gb_assignment.week_id).to eql(::Week.week_containing(m3_assignment.due_date))

      m3_assignment.due_date = m3_assignment.due_date + 1.month
      m3_assignment.save!
      gb_migrator = described_class.new(add_update_params)
      result = gb_migrator.update_object
      expect(result).to be_truthy

      updated_gb_assignment = ::GradebookEngine::Assignment.where(
        activity_id: m3_assignment.assignable_id,
        section_id: m3_assignment.section_id
      ).first
      expect(updated_gb_assignment.day_id).to eql(m3_assignment.due_date)
      expect(updated_gb_assignment.week_id).to eql(::Week.week_containing(m3_assignment.due_date))
    end
  end

  describe 'delete model action', new_gb_sync: true do
    it 'deletes an existing gradebook Assignment record', new_gb_sync: true do
      gb_assignment = ::GradebookEngine::Assignment.where(
        activity_id: m3_assignment.assignable_id,
        section_id: m3_assignment.section_id
      ).first
      expect(gb_assignment.day_id).to eql(m3_assignment.due_date)
      expect(gb_assignment.week_id).to eql(::Week.week_containing(m3_assignment.due_date))

      gb_migrator = described_class.new(m3_assignment.gb_deletion_opts)
      result = gb_migrator.update_object
      expect(result).to be_nil

      deleted_gb_assignment = ::GradebookEngine::Assignment.where(
        activity_id: m3_assignment.assignable_id,
        section_id: m3_assignment.section_id
      ).first
      expect(deleted_gb_assignment).to be_nil
    end
  end
end

describe BulkGbAssignmentCreator, core: true do
  AssignmentAttributes = Struct.new(
    :section_id,
    :activity_id,
    :day_id,
    :week_id,
    :lesson_id,
    :strand_id,
    :category_id,
    :individually_assignable
  )
  let(:course) { build_stubbed(:course) }
  let(:lesson) { create(:lesson )}
  let(:concept) { create(:concept, program: course.program, lesson: lesson )}
  let!(:activity1) { create(:activity, lesson: lesson, concept: concept) }
  let!(:activity2) { create(:activity, lesson: lesson, concept: concept) }
  let(:section_1) { build_stubbed(:section) }
  let(:section_2) { build_stubbed(:section) }
  let(:category) { create(:category, name: 'Learn', weighting_percent: 100) }
  let(:rank) { 4 }
  let(:track_group) { create(:track_group) }
  let(:first_due_date) { Date.tomorrow }
  let(:second_due_date) { Date.tomorrow + 14 }
  let(:activity_schedule) do
    {
      first_due_date.to_s => [
        {
          activities: [{ id: activity1.id }]
        }
      ],
      second_due_date.to_s => [
        {
          activities: [{ id: activity2.id }]
        }
      ]
    }
  end
  let(:creator) { described_class.new(course, [section_1, section_2], {}) }
  let(:activity_calendar) do
    [
      {
        due_date: first_due_date.to_s,
        activity_id: activity1.id,
        track_group_id: track_group.id,
        category: category,
        rank: rank,
        individually_assignable: true
      },
      {
        due_date: second_due_date.to_s,
        activity_id: activity2.id,
        track_group_id: track_group.id,
        category: category,
        rank: rank,
        individually_assignable: false
      }
    ]
  end

  let(:dup_activity_calendar) do
    [
        {
            due_date: first_due_date.to_s,
            activity_id: activity1.id,
            track_group_id: track_group.id,
            category: category,
            rank: rank,
            individually_assignable: true
        },
        {
            due_date: second_due_date.to_s,
            activity_id: activity1.id,
            track_group_id: track_group.id,
            category: category,
            rank: rank,
            individually_assignable: true
        },
        {
            due_date: second_due_date.to_s,
            activity_id: activity2.id,
            track_group_id: track_group.id,
            category: category,
            rank: rank,
            individually_assignable: false
        }
    ]
  end

  describe '#create' do
    before do
      allow(creator).to receive(:activity_calendar).and_return(activity_calendar)
    end

    it 'creates gradebook assignments for each activity in both sections' do
      expect do
        creator.create(activity_schedule)
      end.to change(GradebookEngine::Assignment, :count).by(4)
      attributes = AssignmentAttributes.new(
        section_1.id,
        activity1.id,
        first_due_date,
        ::Week.week_containing(first_due_date),
        activity1.lesson_id,
        activity1.concept_id,
        category.id,
        true
      ).to_h
      expect(GradebookEngine::Assignment.where(attributes)).to exist
      attributes = AssignmentAttributes.new(
        section_2.id,
        activity1.id,
        first_due_date,
        ::Week.week_containing(first_due_date),
        activity1.lesson_id,
        activity1.concept_id,
        category.id,
        true
      ).to_h
      expect(GradebookEngine::Assignment.where(attributes)).to exist
      attributes = AssignmentAttributes.new(
        section_1.id,
        activity2.id,
        second_due_date,
        ::Week.week_containing(second_due_date),
        activity2.lesson_id,
        activity2.concept_id,
        category.id,
        false
      ).to_h
      expect(GradebookEngine::Assignment.where(attributes)).to exist
      attributes = AssignmentAttributes.new(
        section_2.id,
        activity2.id,
        second_due_date,
        ::Week.week_containing(second_due_date),
        activity2.lesson_id,
        activity2.concept_id,
        category.id,
        false
      ).to_h
      expect(GradebookEngine::Assignment.where(attributes)).to exist
    end
  end

  describe '#create with duplicates' do
    before do
      allow(creator).to receive(:activity_calendar).and_return(dup_activity_calendar)
    end

    it 'creates gradebook assignments for each activity in both sections' do
      expect do
        creator.create(activity_schedule)
      end.to change(GradebookEngine::Assignment, :count).by(4)
      attributes = AssignmentAttributes.new(
        section_1.id,
        activity1.id,
        first_due_date,
        ::Week.week_containing(first_due_date),
        activity1.lesson_id,
        activity1.concept_id,
        category.id,
        true
      ).to_h
      expect(GradebookEngine::Assignment.where(attributes)).to exist
      attributes = AssignmentAttributes.new(
        section_2.id,
        activity1.id,
        first_due_date,
        ::Week.week_containing(first_due_date),
        activity1.lesson_id,
        activity1.concept_id,
        category.id,
        true
      ).to_h
      expect(GradebookEngine::Assignment.where(attributes)).to exist
      attributes = AssignmentAttributes.new(
        section_1.id,
        activity2.id,
        second_due_date,
        ::Week.week_containing(second_due_date),
        activity2.lesson_id,
        activity2.concept_id,
        category.id,
        false
      ).to_h
      expect(GradebookEngine::Assignment.where(attributes)).to exist
      attributes = AssignmentAttributes.new(
        section_2.id,
        activity2.id,
        second_due_date,
        ::Week.week_containing(second_due_date),
        activity2.lesson_id,
        activity2.concept_id,
        category.id,
        false
      ).to_h
      expect(GradebookEngine::Assignment.where(attributes)).to exist
    end
  end
end

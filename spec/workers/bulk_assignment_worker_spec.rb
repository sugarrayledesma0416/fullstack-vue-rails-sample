describe BulkAssignmentWorker do
  let(:creator) do
    instance_double(BulkAssignmentCreator, create: nil, categories: nil)
  end
  let(:gb_creator) { instance_double(BulkGbAssignmentCreator, create: nil) }
  let(:course) do
    create(
      :course,
      start_date: Date.today - 2.weeks,
      end_date: Date.today + 3.months
    )
  end
  let(:source_section) { create(:section, course: course) }
  let(:section) { create(:section, course: course) }
  let(:assignments) do
    {
      '1/1/2014' => %w[a b],
      '1/2/2014' => ['c'],
      '1/3/2014' => []
    }
  end
  let(:category_map) { { 'Foo' => 'Bar' } }
  let(:worker) { described_class.new }

  def perform(destroy_old = false)
    worker.perform([section.id], course.id, assignments, category_map, source_section.id, destroy_old)
  end

  before do
    # in order to avoid Redis calls.
    allow(Sidekiq).to receive(:redis).and_return(double('MockRedis'))
    allow(BulkAssignmentCreator).to receive(:new).and_return(creator)
    allow(BulkGbAssignmentCreator).to receive(:new).and_return(gb_creator)
    allow(worker).to receive(:logger).and_return(double('Logger', info: nil))
  end

  context 'when destroy_old flag is set,' do
    let(:lesson_id) { create(:lesson).id }

    it 'deletes only assignments due in the future' do
      # This tests that we do not delete assignments due in the past.
      # In the past is defined as today and earlier.
      test_assignments = {
        (Date.today + 1.week).strftime('%m/%d/%Y') => [],
        (Date.today + 2.weeks).strftime('%m/%d/%Y') => ['a'],
        (Date.today + 3.weeks).strftime('%m/%d/%Y') => %w[a b c]
      }
      assignment_1 = create(
        :assignment,
        section: section,
        assignable_type: 'Activity',
        assignable: create(:activity, lesson_id: lesson_id),
        due_date: Date.yesterday
      )
      assignment_2 = create(
        :assignment,
        section: section,
        assignable_type: 'Activity',
        assignable: create(:activity, lesson_id: lesson_id),
        due_date: Date.today
      )
      assignment_3 = create(
        :assignment,
        section: section,
        assignable_type: 'Activity',
        assignable: create(:activity, lesson_id: lesson_id),
        due_date: Date.today + 1.week
      )
      assignment_4 = create(
        :assignment,
        section: section,
        assignable_type: 'Activity',
        assignable: create(:activity, lesson_id: lesson_id),
        due_date: Date.today + 2.weeks
      )
      worker.perform([section.id], course.id, test_assignments, category_map, source_section.id, true)
      expect(Assignment).to exist(assignment_1.id)
      expect(Assignment).to exist(assignment_2.id)
      expect(Assignment).not_to exist(assignment_3.id)
      expect(Assignment).not_to exist(assignment_4.id)
    end
  end

  context 'when there are no assignments,' do
    it 'still creates the categories in the category map' do
      expect(BulkAssignmentCreator).to receive(:new)
        .with([section], course, category_map, source_section)
        .and_return(creator)
      expect(creator).to receive(:categories)
      expect(creator).not_to receive(:create)
      expect(BulkGbAssignmentCreator).not_to receive(:new)
      worker.perform(
        [section.id],
        course.id,
        { '1/1/2014' => [], '1/8/2014' => [] },
        category_map,
        source_section.id
      )
    end
  end

  describe 'invokes the BulkAssignmentCreator in several chunks' do
    it 'calls the creator on due dates with assignments' do
      expect(BulkAssignmentCreator).to receive(:new)
        .with([section], course, category_map, source_section)
        .and_return(creator)
      expect(creator).to receive(:create).with({ '1/1/2014' => ['a', 'b'] })
      expect(creator).to receive(:create).with({ '1/2/2014' => ['c'] })
      expect(BulkGbAssignmentCreator).to receive(:new).and_return(gb_creator)
      expect(gb_creator).to receive(:create)

      perform
    end

    it 'does not consider due dates with no assignments' do
      expect(BulkAssignmentCreator).to receive(:new).
        with([section], course, category_map, source_section).and_return(creator)
      expect(creator).not_to receive(:create).with({ '1/3/2014' => [] })
      perform
    end
  end
end

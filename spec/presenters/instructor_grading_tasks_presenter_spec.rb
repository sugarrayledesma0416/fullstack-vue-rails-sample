# This class simulates the row format retrieved from the
# GradebookEngine::GradebookAPI query. The results include extra
# attributes that aren't found in a regular ScoreAction, so an instance
# double would raise errors trying to use those results. Instantiating
# real ScoreAction instances would have the same problem. This test record
# class exposes the same methods as the records returned by the query, so
# it should allow the maximum amount of presenter code to be exercised
# without having to stub methods on individual instances.
class FakeGradebookEngineScoreRecord
  attr_accessor :args

  def self.create_upcoming(activity)
    new(
      activity_id: activity.id,
      assigned: true,
      due: false,
      instructor_graded: true,
      pending: true
    )
  end

  def self.create_needs_grading(activity)
    new(
      activity_id: activity.id,
      assigned: true,
      credit_only: false,
      due: true,
      instructor_graded: true,
      pending: true
    )
  end

  def self.create_already_graded(activity)
    new(
      activity_id: activity.id,
      assigned: true,
      credit_only: false,
      due: true,
      instructor_graded: true,
      pending: false
    )
  end

  def self.create_unassigned(activity)
    new(
      activity_id: activity.id,
      assigned: false,
      credit_only: false,
      due: false,
      instructor_graded: true,
      pending: true
    )
  end

  def self.create_smartbook_upcoming(activity)
    new(
      activity_id: activity.id,
      assigned: true,
      due: false,
      instructor_graded: false, # auto_graded
      pending: false,
      partial_pending: true
    )
  end

  def self.create_smartbook_no_need_grading(activity)
    new(
      activity_id: activity.id,
      assigned: true,
      credit_only: false,
      due: true,
      instructor_graded: false, # auto_graded
      pending: false
    )
  end

  def self.create_smartbook_needs_grading(activity)
    new(
      activity_id: activity.id,
      assigned: true,
      credit_only: false,
      due: true,
      instructor_graded: false, # auto_graded
      pending: false,
      partial_pending: true
    )
  end

  def self.create_smartbook_already_graded(activity)
    new(
      activity_id: activity.id,
      assigned: true,
      credit_only: false,
      due: true,
      instructor_graded: false, # auto_graded
      pending: false,
      partial_pending: false
    )
  end

  def self.create_smartbook_unassigned(activity)
    new(
      activity_id: activity.id,
      assigned: false,
      credit_only: false,
      due: false,
      instructor_graded: false, # auto_graded
      pending: false,
      partial_pending: true
    )
  end

  def initialize(args)
    @args = args
  end

  %i[activity_id due_date section_id user_id].each do |method|
    define_method method do
      args[method]
    end
  end

  %i[assigned credit_only due instructor_graded pending partial_pending].each do |method|
    define_method :"#{method}?" do
      args[method] == true
    end
  end

  def partial_pending
    args[:partial_pending]
  end
end

describe InstructorGradingTasksPresenter do
  let(:section) { create(:section) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:student_ids) { [student_1.id, student_2.id] }
  let(:activity_1) { create(:activity, title: 'upcoming') }
  let(:activity_2) { create(:activity, title: 'needs') }
  let(:activity_3) { create(:activity, title: 'already') }
  let(:activity_4) { create(:activity, title: 'unassigned') }

  let(:smartbook_activity_upcoming) do
    create(:activity, title: 'smartbook upcoming')
  end

  let(:smartbook_activity_no_need_grading) do
    create(:activity, title: 'smartbook no needs')
  end

  let(:smartbook_activity_needs_grading) do
    create(:activity, title: 'smartbook needs')
  end

  let(:smartbook_activity_already_graded) do
    create(:activity, title: 'smartbook already')
  end

  let(:smartbook_activity_unassigned) do
    create(:activity, title: 'smartbook unassigned')
  end

  let(:task_set_class) { described_class::GradingTaskSet }
  let(:score_class) { FakeGradebookEngineScoreRecord }
  let(:presenter) do
    described_class.new(section_ids: [section.id], student_ids: student_ids)
  end

  describe '#task_set' do
    let(:upcoming_score) { score_class.create_upcoming(activity_1) }
    let(:needs_grading_score) { score_class.create_needs_grading(activity_2) }
    let(:already_graded_score) { score_class.create_already_graded(activity_3) }
    let(:unassigned_score) { score_class.create_unassigned(activity_4) }

    let(:smartbook_upcoming_score) do
      score_class.create_smartbook_upcoming(smartbook_activity_upcoming)
    end

    let(:smartbook_no_need_grading_score) do
      score_class.create_smartbook_no_need_grading(smartbook_activity_no_need_grading)
    end

    let(:smartbook_needs_grading_score) do
      score_class.create_smartbook_needs_grading(smartbook_activity_needs_grading)
    end

    let(:smartbook_already_graded_score) do
      score_class.create_smartbook_already_graded(smartbook_activity_already_graded)
    end

    let(:smartbook_unassigned_score) do
      score_class.create_smartbook_unassigned(smartbook_activity_unassigned)
    end

    let(:all_scores) do
      [
        upcoming_score,
        needs_grading_score,
        already_graded_score,
        unassigned_score,
        smartbook_upcoming_score,
        smartbook_no_need_grading_score,
        smartbook_needs_grading_score,
        smartbook_already_graded_score,
        smartbook_unassigned_score
      ]
    end

    let(:assigned_activities) do
      [
        activity_1,
        activity_2,
        activity_3,
        smartbook_activity_upcoming,
        smartbook_activity_no_need_grading,
        smartbook_activity_needs_grading,
        smartbook_activity_already_graded
      ]
    end

    before do
      # Set up a spy but don't stub a return value so we use real
      # instances.
      allow(task_set_class).to receive(:new).and_call_original
      allow(GradebookEngine::GradebookAPI).to receive(:grading_set_results)
        .and_return(all_scores)
      assigned_activities.each do |activity|
        create(:assignment, assignable: activity, section: section)
      end
    end

    it 'queries the GradebookAPI specifying the sections and students with ' \
       'which the presenter was initialized' do
      presenter.task_set(nil)

      expect(GradebookEngine::GradebookAPI).to have_received(:grading_set_results)
        .with(section_ids: [section.id], user_ids: student_ids)
    end

    context 'when no assignments are individually assignable,' do
      let(:assigned_students_by_activity) do
        assigned_activities.each_with_object({}) do |activity, memo|
          memo[activity.id] = student_ids
        end
      end

      let(:unassigned_students_by_activity) do
        assigned_activities.each_with_object({}) do |activity, memo|
          memo[activity.id] = []
        end.merge(
          activity_4.id => student_ids,
          smartbook_activity_unassigned.id => student_ids
        )
      end

      before do
        create(:active_enrollment, section: section, user: student_1)
        create(:completed_enrollment, section: section, user: student_2)
        create(:dropped_enrollment, section: section, user: create(:student))
        create(:transferred_enrollment, section: section, user: create(:student))
      end

      it 'instantiates the GradingTaskSets for assigned work with a hash ' \
         'keyed on activity with all the enrolled student_ids as the values' do
        presenter.task_set(nil)

        expect(task_set_class).to have_received(:new)
          .exactly(3).times
          .with(hash_including(student_ids: assigned_students_by_activity))
      end

      it 'instantiates the GradingTaskSet for unassigned work with a hash ' \
         'keyed on activity with all the enrolled student_ids as the value ' \
         'for unassigned activities and an empty array for assigned activities' do
        presenter.task_set(nil)

        expect(task_set_class).to have_received(:new)
          .once
          .with(hash_including(student_ids: unassigned_students_by_activity))
      end
    end

    context 'when some activities are individually assignable,' do
      before do
        create(:active_enrollment, section: section, user: student_1)
        allow(GradebookEngine::GradebookAPI).to receive(:grading_set_results)
          .and_return([upcoming_score])
        Assignment.find_by(assignable_id: activity_1.id).update!(
          individually_assignable: true
        )
      end

      context 'when an assignment is individually assigned to some students,' do
        before do
          IndividualAssignment.create!(
            activity_id: activity_1.id,
            section_id: section.id,
            user_id: student_1.id
          )
        end

        it 'instantiates the GradingTaskSets for assigned work with a hash ' \
           'keyed on activity with the user_ids of the individually assigned ' \
           'students as the value' do
          presenter.task_set(nil)

          expect(task_set_class).to have_received(:new).exactly(3).times.with(
            hash_including(student_ids: { activity_1.id => [student_1.id] })
          )
        end

        it 'instantiates the GradingTaskSet for unassigned work with a hash ' \
           'keyed on activity with the user_ids of the students who are ' \
           'not individually assigned as the value for the assigned activity' do
          presenter.task_set(nil)

          expect(task_set_class).to have_received(:new).once.with(
            hash_including(student_ids: { activity_1.id => [student_2.id] })
          )
        end
      end

      context 'when an assignment is individually assigned in one section ' \
              'and assigned to all students in another section,' do
        let(:other_section) { create(:section) }

        let(:presenter) do
          described_class.new(
            section_ids: [section.id, other_section.id],
            student_ids: student_ids
          )
        end

        before do
          IndividualAssignment.create!(
            activity_id: activity_1.id,
            section_id: section.id,
            user_id: student_1.id
          )
          create(
            :assignment,
            assignable: activity_1,
            individually_assignable: false,
            section: other_section
          )
          create(:active_enrollment, section: other_section, user: student_2)
        end

        it 'instantiates the GradingTaskSets for assigned work with a hash ' \
           'keyed on activity with the user_ids of the individually assigned ' \
           'students plus all the enrolled students in the section in which ' \
           'it is not individually-assignable as the value' do
          presenter.task_set(nil)

          expect(task_set_class).to have_received(:new).exactly(3).times.with(
            hash_including(
              student_ids: { activity_1.id => [student_1.id, student_2.id] }
            )
          )
        end
      end
    end

    context 'when called with "Upcoming Grading" task,' do
      it 'instantiates the GradingTaskSet with a set of GradebookEngine' \
         'results for which upcoming_grading? returns true' do
        presenter.task_set(GradingTask::UPCOMING_GRADING)

        expect(task_set_class).to have_received(:new)
          .with(hash_including(reviewable_scores: [upcoming_score, smartbook_upcoming_score]))
          .once
      end

      it 'returns the newly instantiated GradingTaskSet' do
        result = presenter.task_set(GradingTask::UPCOMING_GRADING)
        expect(result.unique_activities).to eq([activity_1, smartbook_activity_upcoming])
      end
    end

    context 'when called with "Needs Grading" task,' do
      it 'instantiates the GradingTaskSet with a set of GradebookEngine' \
         'results for which needs_grading? returns true' do
        presenter.task_set(GradingTask::NEEDS_GRADING)

        expect(task_set_class).to have_received(:new)
          .with(hash_including(reviewable_scores: [needs_grading_score, smartbook_needs_grading_score]))
          .once
      end

      it 'returns the newly instantiated GradingTaskSet' do
        result = presenter.task_set(GradingTask::NEEDS_GRADING)
        expect(result.unique_activities).to eq([activity_2, smartbook_activity_needs_grading])
      end
    end

    context 'when called with "Already Graded" task,' do
      it 'instantiates the GradingTaskSet with a set of GradebookEngine' \
         'results for which already_graded? returns true' do
        presenter.task_set(GradingTask::ALREADY_GRADED)

        expect(task_set_class).to have_received(:new)
          .with(hash_including(reviewable_scores: [already_graded_score, smartbook_already_graded_score]))
          .once
      end

      it 'instantiates the GradingTaskSet with a list of activities that ' \
         'should be excluded' do
        presenter.task_set(GradingTask::ALREADY_GRADED)

        expect(task_set_class).to have_received(:new)
          .with(hash_including(exclusions: [
            activity_1, smartbook_activity_upcoming,
            activity_2, smartbook_activity_needs_grading
        ])).once
      end

      it 'returns the newly instantiated GradingTaskSet' do
        result = presenter.task_set(GradingTask::ALREADY_GRADED)
        expect(result.unique_activities).to eq([activity_3, smartbook_activity_already_graded])
      end
    end

    context 'when called with "Unassigned Activities" task,' do
      it 'instantiates the GradingTaskSet with a set of GradebookEngine' \
         'results for which unassigned_pending? returns true' do
        presenter.task_set(GradingTask::UNASSIGNED_ACTIVITIES)

        expect(task_set_class).to have_received(:new)
          .with(hash_including(reviewable_scores: [unassigned_score, smartbook_unassigned_score]))
          .once
      end

      it 'returns the newly instantiated GradingTaskSet' do
        result = presenter.task_set(GradingTask::UNASSIGNED_ACTIVITIES)
        expect(result.unique_activities).to eq([activity_4, smartbook_activity_unassigned])
      end
    end
  end

  describe '#tasklist_count' do
    it 'returns the count of activities for the specified task type' do
      scores = [
        score_class.create_needs_grading(activity_1),
        score_class.create_already_graded(activity_2),
        score_class.create_already_graded(activity_3),
        score_class.create_unassigned(create(:activity)),
        score_class.create_unassigned(create(:activity)),
        score_class.create_unassigned(create(:activity))
      ]
      allow(GradebookEngine::GradebookAPI).to receive(:grading_set_results)
        .and_return(scores)

      results = [
        presenter.tasklist_count(GradingTask::UPCOMING_GRADING),
        presenter.tasklist_count(GradingTask::NEEDS_GRADING),
        presenter.tasklist_count(GradingTask::ALREADY_GRADED),
        presenter.tasklist_count(GradingTask::UNASSIGNED_ACTIVITIES)
      ]
      expect(results).to eq([0, 1, 2, 3])
    end
  end
end

describe InstructorGradingTasksPresenter::GradingTaskSet do
  let(:section) { build_stubbed(:section) }
  let(:student_1) { build_stubbed(:student) }
  let(:student_2) { build_stubbed(:student) }
  let(:student_ids) { [student_1.id, student_2.id] }
  let(:score_class) { FakeGradebookEngineScoreRecord }
  let(:activity_1) { create(:activity) }
  let(:activity_2) { create(:activity) }

  def create_task_set(reviewable_scores: [], **args)
    reviewable_scores.each do |score|
      score.extend(InstructorGradingTasksPresenter::TaskSetPredicates)
      score.stashed_activity = Activity.find(score.activity_id)
    end
    described_class.new(
      {
        reviewable_scores:,
        student_ids: {
          activity_1.id => student_ids,
          activity_2.id => student_ids
        },
      }.merge(args)
    )
  end

  describe '#assignment_count' do
    it 'returns 0 if no scores are specified' do
      task_set = create_task_set(reviewable_scores: [])
      expect(task_set.assignment_count).to be 0
    end

    context 'when no exclusions are specified,' do
      it 'returns the count of unique activities even if multiple scores ' \
         'reference the same activity' do
        scores = [
          score_class.new(activity_id: activity_1.id),
          score_class.new(activity_id: activity_1.id),
          score_class.new(activity_id: activity_2.id),
          score_class.new(activity_id: activity_2.id)
        ]
        task_set = create_task_set(reviewable_scores: scores)
        expect(task_set.assignment_count).to be 2
      end
    end

    context 'when exclusions are specified,' do
      it 'counts only activities not specified by the exclusions' do
        scores = [
          score_class.new(activity_id: activity_1.id),
          score_class.new(activity_id: activity_2.id)
        ]
        task_set = create_task_set(
          exclusions: [activity_1],
          reviewable_scores: scores
        )
        expect(task_set.assignment_count).to be 1
      end
    end
  end

  describe '#due_date_for_activity' do
    it 'returns nil when initialized with no scores' do
      task_set = create_task_set(reviewable_scores: [])
      create(:assignment, assignable: activity_1, section: section)
      expect(task_set.due_date_for_activity(activity_1)).to be_nil
    end

    it 'returns nil if none of the activities specified by the scores are ' \
       'assigned in the specified sections' do
      other_section = create(:section)
      create(:assignment, assignable: activity_1, section: other_section)
      task_set = create_task_set(
        reviewable_scores: [
          score_class.new(activity_id: activity_1.id, section_id: section.id)
        ]
      )
      expect(task_set.due_date_for_activity(activity_1)).to be_nil
    end

    context 'when more than one of the activities specified by the scores ' \
            'are assigned in the specified sections,' do
      it 'returns the due_date for the specified activity' do
        due_date_1 = 5.days.from_now
        due_date_2 = 5.days.ago
        task_set = create_task_set(
          reviewable_scores: [
            score_class.new(activity_id: activity_1.id, due_date: due_date_1),
            score_class.new(activity_id: activity_2.id, due_date: due_date_2)
          ]
        )
        expect(task_set.due_date_for_activity(activity_1)).to eq(due_date_1)
      end
    end
  end

  describe '#number_to_be_graded' do
    it 'returns 0 if no scores are specified' do
      task_set = create_task_set(reviewable_scores: [])
      expect(task_set.number_to_be_graded(activity_1)).to be 0
    end

    it 'returns the number of scores for the specified activity id' do
      scores = [
        score_class.new(activity_id: activity_1.id),
        score_class.new(activity_id: activity_1.id)
      ]
      task_set = create_task_set(reviewable_scores: scores)
      expect(task_set.number_to_be_graded(activity_1)).to be 2
    end
  end

  describe '#submission_counts_for_activity' do
    let(:score_1) do
      score_class.new(
        user_id: student_1.id,
        section_id: section.id,
        activity_id: activity_1.id
      )
    end
    let(:score_2) do
      score_class.new(
        user_id: student_1.id,
        section_id: section.id,
        activity_id: activity_2.id
      )
    end
    let(:score_3) do
      score_class.new(
        user_id: student_2.id,
        section_id: section.id,
        activity_id: activity_2.id
      )
    end
    let(:submitted_scores) { [score_1, score_2, score_3] }

    it 'returns 0 in the submitted_scores hash value when initialized with no students' do
      student_ids = { activity_1.id => [] }
      task_set = create_task_set(
        submitted_scores:,
        student_ids:
      )
      expect(task_set.submission_counts_for_activity(activity_1)[:assigned_count]).to be 0
    end

    it 'returns a hash with the number of submissions and the number of assignments ' \
       'for a specific activity' do
      student_ids = {
        activity_1.id => [student_1.id, student_2.id],
        activity_2.id => [student_1.id, student_2.id]
      }
      task_set = create_task_set(
        submitted_scores:,
        student_ids:
      )
      expect(task_set.submission_counts_for_activity(activity_1)[:assigned_count]).to be 2
      expect(task_set.submission_counts_for_activity(activity_1)[:submitted_count]).to be 1
    end

    it 'returns a hash with the number of submissions and the number of assignments ' \
       'for a specific activity that has scores from concurrent enrolled students' do
      section_2 = create(:section)
      student_3 = create(:student)
      score_1 = score_class.new(
        user_id: student_1.id,
        section_id: section.id,
        activity_id: activity_1.id
      )
      score_2 = score_class.new(
        user_id: student_1.id,
        section_id: section_2.id,
        activity_id: activity_1.id
      )
      score_3 = score_class.new(
        user_id: student_2.id,
        section_id: section.id,
        activity_id: activity_1.id
      )
      submitted_scores = [score_1, score_2, score_3]
      student_ids = {
        activity_1.id => [student_1.id, student_2.id, student_1.id, student_3.id]
      }
      task_set = create_task_set(
        submitted_scores:,
        student_ids:
      )
      expect(task_set.submission_counts_for_activity(activity_1)[:assigned_count]).to be 4
      expect(task_set.submission_counts_for_activity(activity_1)[:submitted_count]).to be 3
    end
  end

  describe '#sorted_activities' do
    it 'returns unique activities sorted by toc order' do
      lesson_1 = create(:lesson_with_toc_entries, rank: 1)
      lesson_2 = create(:lesson_with_toc_entries, rank: 2)
      # Create out of order so things don't pass because of default id sort.
      lesson_2_activity = create(
        :activity,
        lesson: lesson_2,
        toc_location: lesson_2.strands.first.location,
        toc_location_rank: 1
      )
      lesson_1_activity_2 = create(
        :activity,
        lesson: lesson_1,
        toc_location: lesson_1.strands.first.location,
        toc_location_rank: 2
      )
      lesson_1_activity_1 = create(
        :activity,
        lesson: lesson_1,
        toc_location: lesson_1.strands.first.location,
        toc_location_rank: 1
      )
      activities = [lesson_1_activity_1, lesson_1_activity_2, lesson_2_activity]
      scores = [
        # Create two scores with same activity to test uniqueness.
        score_class.new(activity_id: lesson_2_activity.id),
        score_class.new(activity_id: lesson_2_activity.id),
        score_class.new(activity_id: lesson_1_activity_2.id),
        score_class.new(activity_id: lesson_1_activity_1.id)
      ]
      task_set = create_task_set(reviewable_scores: scores)
      expect(task_set.sorted_activities).to eq(activities)
    end
  end

  describe '#students_for_activity' do
    it 'returns an empty array if there are no scores for the specified ' \
       'activity' do
      task_set = create_task_set(reviewable_scores: [])
      expect(task_set.students_for_activity(activity_1)).to eq([])
    end

    it 'returns an array of the user ids from only the scores for the ' \
       'specified activity' do
      scores = [
        score_class.new(activity_id: activity_1.id, user_id: student_1.id),
        score_class.new(activity_id: activity_2.id, user_id: student_2.id)
      ]
      task_set = create_task_set(reviewable_scores: scores)
      expect(task_set.students_for_activity(activity_1)).to eq([student_1.id])
    end
  end

  describe '#unique_activities' do
    it 'returns an empty array if no scores are specified' do
      task_set = create_task_set(reviewable_scores: [])
      expect(task_set.unique_activities).to eq([])
    end

    context 'when no exclusions are specified,' do
      it 'returns activities with no duplicates even if multiple scores ' \
         'reference the same activity' do
        scores = [
          score_class.new(activity_id: activity_1.id),
          score_class.new(activity_id: activity_1.id),
          score_class.new(activity_id: activity_2.id),
          score_class.new(activity_id: activity_2.id)
        ]
        task_set = create_task_set(reviewable_scores: scores)
        expect(task_set.unique_activities).to match_array(
          [activity_1, activity_2]
        )
      end
    end

    context 'when exclusions are specified,' do
      it 'returns only activities not specified by the exclusions' do
        scores = [
          score_class.new(activity_id: activity_1.id),
          score_class.new(activity_id: activity_2.id)
        ]
        task_set = create_task_set(exclusions: [activity_1], reviewable_scores: scores)
        expect(task_set.unique_activities).to eq([activity_2])
      end
    end
  end
end

describe InstructorGradingTasksPresenter::TaskSetPredicates do
  let(:score_class) { FakeGradebookEngineScoreRecord }

  def create_score_using_module(attrs)
    score_class.new(attrs).extend(described_class)
  end

  describe '#upcoming_grading?' do
    let(:true_attrs) do
      {
        assigned: true,
        due: false,
        pending: true
      }
    end

    it 'is false if not assigned' do
      score = create_score_using_module(true_attrs.merge(assigned: false))
      expect(score).not_to be_upcoming_grading
    end

    it 'is false if not pending' do
      score = create_score_using_module(true_attrs.merge(pending: false))
      expect(score).not_to be_upcoming_grading
    end

    context 'when assigned and not due,' do
      it 'is true if pending' do
        score = create_score_using_module(assigned: true, due: false, pending: true)
        expect(score).to be_upcoming_grading
      end

      context 'when not pending,' do
        let(:attrs) { { assigned: true, due: false, pending: false } }

        it 'is false if partial_pending attribute does not exist' do
          score = create_score_using_module(attrs)
          expect(score).not_to be_upcoming_grading
        end

        it 'is false if partial_pending is false' do
          score = create_score_using_module(attrs.merge(pending: false, partial_pending: false))
          expect(score).not_to be_upcoming_grading
        end

        it 'is true if partial_pending is true' do
          score = create_score_using_module(attrs.merge(pending: false, partial_pending: true))
          expect(score).to be_upcoming_grading
        end
      end
    end

    context 'when assigned and pending,' do
      it 'is false if due' do
        score = create_score_using_module(true_attrs.merge(due: true))
        expect(score).not_to be_upcoming_grading
      end

      it 'is true if not yet due' do
        score = create_score_using_module(true_attrs)
        expect(score).to be_upcoming_grading
      end
    end
  end

  describe '#needs_grading?' do
    let(:true_attrs) do
      {
        assigned: true,
        credit_only: false,
        due: true,
        pending: true
      }
    end

    it 'is false if not assigned' do
      score = create_score_using_module(true_attrs.merge(assigned: false))
      expect(score).not_to be_needs_grading
    end

    it 'is false if not pending' do
      score = create_score_using_module(true_attrs.merge(pending: false))
      expect(score).not_to be_needs_grading
    end

    it 'is false if not due' do
      score = create_score_using_module(true_attrs.merge(due: false))
      expect(score).not_to be_needs_grading
    end

    context 'when assigned and due and not pending,' do
      let(:attrs) do
        { assigned: true, due: true, pending: false }
      end

      it 'is false if partial_pending attribute does not exist' do
        score = create_score_using_module(attrs)
        expect(score).not_to be_needs_grading
      end

      it 'is false if partial_pending is false' do
        score = create_score_using_module(attrs.merge(partial_pending: false))
        expect(score).not_to be_needs_grading
      end

      it 'is true if partial_pending is true' do
        score = create_score_using_module(attrs.merge(partial_pending: true))
        expect(score).to be_needs_grading
      end
    end

    context 'when assigned and pending and due,' do
      it 'is false if assigned in a credit-only category' do
        score = create_score_using_module(true_attrs.merge(credit_only: true))
        expect(score).not_to be_needs_grading
      end

      it 'is true if not assigned in a credit-only category' do
        score = create_score_using_module(true_attrs)
        expect(score).to be_needs_grading
      end
    end
  end

  describe '#already_graded?' do
    let(:true_attrs) do
      {
        assigned: true,
        instructor_graded: true,
        pending: false
      }
    end

    it 'is false if not assigned' do
      score = create_score_using_module(true_attrs.merge(assigned: false))
      expect(score).not_to be_already_graded
    end

    it 'is false if pending' do
      score = create_score_using_module(true_attrs.merge(pending: true))
      expect(score).not_to be_already_graded
    end

    context 'when assigned and not pending,' do
      let(:attrs) { { assigned: true, pending: false } }

      it 'is false if not instructor-graded' do
        score = create_score_using_module(attrs.merge(instructor_graded: false))
        expect(score).not_to be_already_graded
      end

      it 'is true if instructor-graded' do
        score = create_score_using_module(attrs.merge(instructor_graded: true))
        expect(score).to be_already_graded
      end
    end

    context 'when assigned and pending,' do
      let(:attrs) { { assigned: true, pending: true } }

      context 'when partial_pending attribute does not exist,' do
        it 'is false' do
          score = create_score_using_module(attrs)
          expect(score).not_to be_already_graded
        end
      end

      context 'when partial_pending is false,' do
        it 'is true' do
          score = create_score_using_module(attrs.merge(partial_pending: false))
          expect(score).to be_already_graded
        end
      end

      context 'when partial_pending is true,' do
        it 'is false' do
          score = create_score_using_module(attrs.merge(partial_pending: true))
          expect(score).not_to be_already_graded
        end
      end
    end
  end

  describe '#unassigned_pending?' do
    it 'is false if assigned' do
      score = create_score_using_module(assigned: true, pending: true)
      expect(score).not_to be_unassigned_pending
    end

    it 'is false if not pending' do
      score = create_score_using_module(assigned: false, pending: false)
      expect(score).not_to be_unassigned_pending
    end

    it 'is true if pending and not assigned' do
      score = create_score_using_module(assigned: false, pending: true)
      expect(score).to be_unassigned_pending
    end

    it 'is true if not partially pending and not assigned' do
      score = create_score_using_module(assigned: false, pending: false, partial_pending: true)
      expect(score).to be_unassigned_pending
    end
  end
end

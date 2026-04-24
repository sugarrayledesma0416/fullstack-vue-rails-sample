describe DueDate::QueryBuilder do
  describe '.base_scope' do
    let(:user_id) { create(:user).id }
    let(:section) { create(:section) }
    let(:section_id) { section.id }
    let(:due_date) { section.course.start_date + 7 }
    let(:other_due_date) { due_date + 1 }
    let(:unit) { create(:unit, rank: 10) }
    let(:lesson) { create(:lesson, id: 100, unit: unit) }
    let(:concept) { create(:concept, lesson: lesson, media_item_id: 456) }
    let(:activity) do
      create(:activity, lesson: lesson, concept: concept, title: 'not external!')
    end
    let(:results) do
      described_class.new(user_id, section_id).assignments_for(due_date)
    end

    let(:submitted_status) { AttemptStatus::CODE_SUBMITTED }

    it 'returns only assignments for the specified section' do
      other_section_id = create(:section).id

      create(:assignment, section_id: section_id, due_date: due_date)
      create(:assignment, section_id: other_section_id, due_date: due_date)

      expect(results.map(&:section_id).uniq).to eq([section_id])
    end

    it 'returns only assignments for the specified due date' do

      create(:assignment, section_id: section_id, due_date: due_date)
      create(:assignment, section_id: section_id, due_date: other_due_date)

      expect(results.map(&:due_date).uniq).to eq([due_date])
    end

    context 'when some activities are assigned individually,' do
      it 'includes only the activities assigned to all students or the ' \
         'current student' do
        # Not individually assigned
        all_students_assignment = create(
          :assignment,
          due_date: due_date,
          individually_assignable: false,
          section_id: section_id
        )

        # individually assigned to current student
        individual_student_assignment = create(
          :assignment,
          assignable: activity,
          due_date: due_date,
          individually_assignable: true,
          section_id: section_id
        )

        IndividualAssignment.create!(
          activity_id: activity.id,
          section_id: section.id,
          user_id: user_id
        )

        # individually assigned, but not to current student
        create(
          :assignment,
          due_date: due_date,
          individually_assignable: true,
          section_id: section_id
        )

        expect(results.map(&:assignable_id)).to contain_exactly(
          all_students_assignment.assignable_id,
          individual_student_assignment.assignable_id
        )

        # Verify correct field retrieved via SELECT statement
        expect(results.map(&:due_date)).to contain_exactly(
          due_date, due_date
        )
      end
    end

    context 'when some activities are assigned with individual due dates,' do
      it 'includes only the activities assigned to all students or the ' \
         'current student with no individual due date, or the current ' \
         'student with an individual due date matching the specified date' do
        # Not individually assigned
        all_students_assignment = create(
          :assignment,
          due_date: due_date,
          individually_assignable: false,
          section_id: section_id
        )

        # individually assigned to current student, no individual due date
        individual_assignment_no_due_date = create(
          :assignment,
          assignable: activity,
          due_date: due_date,
          individually_assignable: true,
          section_id: section_id
        )

        IndividualAssignment.create!(
          activity_id: activity.id,
          section_id: section.id,
          user_id: user_id
        )

        # individually assigned to current student, individual due date
        # matching specified date
        individual_assignment_matching_due_date = create(
          :assignment,
          due_date: other_due_date,
          individually_assignable: true,
          section_id: section_id
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_matching_due_date.assignable_id,
          due_date: due_date,
          section_id: section.id,
          user_id: user_id
        )

        # individually assigned to current student, individual due date
        # different from specified date
        individual_assignment_non_matching_due_date = create(
          :assignment,
          due_date: due_date,
          individually_assignable: true,
          section_id: section_id
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_non_matching_due_date.assignable_id,
          due_date: other_due_date,
          section_id: section.id,
          user_id: user_id
        )

        # individually assigned, but not to current student
        other_student_assignment = create(
          :assignment,
          due_date: other_due_date,
          individually_assignable: true,
          section_id: section_id
        )

        IndividualAssignment.create!(
          activity_id: other_student_assignment.assignable_id,
          due_date: due_date,
          section_id: section.id,
          user_id: create(:student).id
        )

        expect(results.map(&:assignable_id)).to contain_exactly(
          all_students_assignment.assignable_id,
          individual_assignment_no_due_date.assignable_id,
          individual_assignment_matching_due_date.assignable_id
        )

        # Verify correct field retrieved via SELECT statement
        expect(results.map(&:due_date)).to contain_exactly(
          due_date, due_date, due_date
        )
      end
    end

    it 'includes lesson and concept attributes' do
      create(
        :assignment,
        section_id: section_id,
        due_date: due_date,
        assignable: activity
      )
      result = results.first

      expect(result.lesson_id).to eq(lesson.id)
      expect(result.lesson_name).to eq(lesson.name)
      expect(result.concept_id).to eq(concept.id)
      expect(result.concept_name).to eq(concept.name)
      expect(result.concept_media_item_id).to eq(concept.media_item_id)
    end

    it 'returns lesson label as lesson name if lesson label exists' do
      label = 'my label!'
      lesson.update!(label: label)
      create(
        :assignment,
        section_id: section_id,
        due_date: due_date,
        assignable: activity
      )

      expect(results.first.lesson_name).to eq(label)
    end

    it 'returns attempt status only for the specified student, ignoring reset status' do
      user_2 = create(:user)

      create(
        :attempt_submitted,
        user_id: user_id,
        activity_id: activity.id,
        section_id: section_id
      )
      create(
        :attempt_reset,
        user_id: user_2.id,
        activity_id: activity.id,
        section_id: section_id
      )
      create(
        :attempt_completed,
        user_id: user_2.id,
        activity_id: activity.id,
        section_id: section_id
      )
      create(
        :assignment,
        section_id: section_id,
        assignable_id: activity.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )

      expect(results[0].status_code).to eq(submitted_status)
      expect(results.size).to eq(1)
    end

    it 'only returns attempt status for attempts with the specified section id' do
      section_2 = create(:section)
      create(
        :attempt_completed,
        user_id: user_id,
        activity_id: activity.id,
        section_id: section_2.id
      )
      create(
        :attempt_submitted,
        user_id: user_id,
        activity_id: activity.id,
        section_id: section_id
      )
      create(
        :assignment,
        section_id: section_id,
        assignable_id: activity.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      create(
        :assignment,
        section_id: section_2.id,
        assignable_id: activity.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      expect(results[0].status_code).to eq(submitted_status)
      expect(results.size).to eq(1)
    end

    it 'only returns attempt status for activities assigned on the specified due date' do
      due_date_2 = due_date + 1

      activity_2 = create(:activity, lesson: lesson, concept: concept)
      create(
        :attempt_completed,
        user_id: user_id,
        activity_id: activity.id,
        section_id: section_id
      )
      create(
        :attempt_submitted,
        user_id: user_id,
        activity_id: activity_2.id,
        section_id: section_id
      )
      create(
        :assignment,
        section_id: section_id,
        assignable_id: activity_2.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      create(
        :assignment,
        section_id: section_id,
        assignable_id: activity.id,
        due_date: due_date_2,
        assignable_type: 'Activity'
      )
      expect(results[0].status_code).to eq(submitted_status)
      expect(results.size).to eq(1)

    end

    it 'returns assignments ordered by unit.rank, lesson.rank, activities.concept_rank,
        assignment.rank' do
      unit_2 = create(:unit, rank: 20)
      lesson_2 = create(:lesson, unit: unit_2)
      activity_2 = create(
        :activity,
        lesson: lesson_2,
        concept_rank: 1
      )
      create(
        :attempt_completed,
        user_id: user_id,
        activity_id: activity.id,
        section_id: section_id
      )
      create(
        :attempt_submitted,
        user_id: user_id,
        activity_id: activity_2.id,
        section_id: section_id
      )
      create(
        :assignment,
        rank: 30,
        section_id: section_id,
        assignable_id: activity_2.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      create(
        :assignment,
        rank: 10,
        section_id: section_id,
        assignable_id: activity.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      expect(results.map(&:assignable_id)).to eq([activity.id, activity_2.id])
    end

    context 'when unit.rank tie for some assignments' do
      let(:lesson_2) { create(:lesson, rank: 20, unit: unit) }
      let(:lesson_3) { create(:lesson, rank: 30, unit: unit) }
      let(:activity_2) do
        create(
          :activity,
          lesson: lesson_2,
          concept_rank: 1
        )
      end
      let(:activity_3) do
        create(
          :activity,
          lesson: lesson_3,
          concept_rank: 1
        )
      end

      before do
        create(
          :attempt_completed,
          user_id: user_id,
          activity_id: activity_3.id,
          section_id: section_id
        )
        create(
          :attempt_submitted,
          user_id: user_id,
          activity_id: activity_2.id,
          section_id: section_id
        )
        create(
          :assignment,
          rank: 10,
          section_id: section_id,
          assignable_id: activity_2.id,
          due_date: due_date,
          assignable_type: 'Activity'
        )
        create(
          :assignment,
          rank: 10,
          section_id: section_id,
          assignable_id: activity_3.id,
          due_date: due_date,
          assignable_type: 'Activity'
        )
      end

      it 'returns assignments ordered by lesson.rank when unit.rank tie' do
        expect(results.map(&:assignable_id)).to eq([activity_2.id, activity_3.id])
      end

      it 'returns assignments ordered by lesson.rank even when the lesson
          were created in the opposite order' do
        lesson_2.rank = 40
        lesson_2.save

        expect(results.map(&:assignable_id)).to eq([activity_3.id, activity_2.id])
      end
    end

    it 'returns assignments ordered by activity.concept_rank when unit.rank and
        lesson.rank tie' do
      activity_2 = create(
        :activity,
        lesson: lesson,
        concept_rank: 10
      )
      activity_3 = create(
        :activity,
        lesson: lesson,
        concept_rank: 20
      )
      create(
        :attempt_completed,
        user_id: user_id,
        activity_id: activity_3.id,
        section_id: section_id
      )
      create(
        :attempt_submitted,
        user_id: user_id,
        activity_id: activity_2.id,
        section_id: section_id
      )
      create(
        :assignment,
        rank: 10,
        section_id: section_id,
        assignable_id: activity_2.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      create(
        :assignment,
        rank: 10,
        section_id: section_id,
        assignable_id: activity_3.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      expect(results.map(&:assignable_id)).to eq([activity_2.id, activity_3.id])
    end

    it 'returns assignments ordered by assignment.rank when unit.rank, lesson.rank
        and activity.concept_rank tie' do
      activity_2 = create(
        :activity,
        lesson: lesson,
        concept_rank: 10
      )
      activity_3 = create(
        :activity,
        lesson: lesson,
        concept_rank: 10
      )
      create(
        :attempt_completed,
        user_id: user_id,
        activity_id: activity_3.id,
        section_id: section_id
      )
      create(
        :attempt_submitted,
        user_id: user_id,
        activity_id: activity_2.id,
        section_id: section_id
      )
      create(
        :assignment,
        rank: 10,
        section_id: section_id,
        assignable_id: activity_2.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      create(
        :assignment,
        rank: 20,
        section_id: section_id,
        assignable_id: activity_3.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      expect(results.map(&:assignable_id)).to eq([activity_2.id, activity_3.id])
    end

    it 'returns assignments ordered by activity.toc_location_rank when assignment.rank, unit.rank, lesson.rank
        and activity.concept_rank tie' do
      activity_2 = create(
        :activity,
        lesson: lesson,
        concept_rank: 10,
        toc_location_rank: 20
      )
      activity_3 = create(
        :activity,
        lesson: lesson,
        concept_rank: 10,
        toc_location_rank: 30
      )
      create(
        :attempt_completed,
        user_id: user_id,
        activity_id: activity_3.id,
        section_id: section_id
      )
      create(
        :attempt_submitted,
        user_id: user_id,
        activity_id: activity_2.id,
        section_id: section_id
      )
      create(
        :assignment,
        rank: 10,
        section_id: section_id,
        assignable_id: activity_2.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      create(
        :assignment,
        rank: 10,
        section_id: section_id,
        assignable_id: activity_3.id,
        due_date: due_date,
        assignable_type: 'Activity'
      )
      expect(results.map(&:assignable_id)).to eq([activity_2.id, activity_3.id])
    end

    it 'returns the background color for each concept' do
      concept_2 = create(:concept, lesson: lesson)

      due_date_2 = due_date + 1

      activity_2 = create(:activity, lesson: lesson, concept: concept_2)
      create(:attempt_completed, user_id: user_id, activity_id: activity.id, section_id: section_id)
      create(:attempt_submitted, user_id: user_id, activity_id: activity_2.id, section_id: section_id)
      create(:assignment, section_id: section_id, assignable_id: activity_2.id, due_date: due_date, assignable_type: 'Activity')
      create(:assignment, section_id: section_id, assignable_id: activity.id, due_date: due_date_2, assignable_type: 'Activity')

      expect(results[0].concept_color).to eq(concept_2.background_color)
      expect(results.size).to eq(1)
    end

    context 'when there are assignment sets with custom ranks' do
      let(:activity_2) { create(:activity, lesson: lesson, concept_rank: 10) }
      let(:activity_3) { create(:activity, lesson: lesson, concept_rank: 10) }

      let(:assignment_set_1) do
        create(
          :assignment_set,
          due_date: due_date,
          section_id: section_id
        )
      end

      let(:assignment_set_2) do
        create(
          :assignment_set,
          due_date: due_date + 1,
          section_id: section_id
        )
      end

      before do
        create(
          :assignment,
          assignable: activity,
          due_date: due_date,
          rank: 10,
          section_id: section_id
        )

        create(
          :assignment,
          assignable: activity_2,
          due_date: due_date,
          rank: 20,
          section_id: section_id
        )

        create(
          :assignment_set_activity,
          activity: activity,
          assignment_set: assignment_set_1,
          assignment_set_rank: 2
        )

        create(
          :assignment_set_activity,
          activity: activity_2,
          assignment_set: assignment_set_1,
          assignment_set_rank: 1
        )

        # should not get included in the results
        create(
          :assignment_set_activity,
          activity: activity_3,
          assignment_set: assignment_set_2,
          assignment_set_rank: 3
        )
      end

      it 'sorts the assignments by the custom rank' do
        expect(results.map(&:assignable_id)).to eq([activity_2.id, activity.id])
      end

      it 'returns the custom rank as the rank attribute instead of ' \
         'the rank from the assignment record' do
        expect(results.map(&:rank)).to eq([1, 2])
      end
    end
  end
end

describe DueDate do
  let(:user_id) { create(:user).id }
  let(:due_date) { Date.today }
  let(:mock_assignment_group) { double('AssignmentGroup') }
  let(:mock_query_builder) { double(DueDate::QueryBuilder, assignments_for: [completed_assignment]) }
  let(:subject) { described_class.new(section.id, due_date, user_id) }
  let(:concept_1_media_item_id) { 345 }
  let(:concept_2_media_item_id) { 456 }

  let(:noncompleted_assignment) do
    double(
      'Assignment',
      status_code: AttemptStatus::CODE_OPENED,
      minutes_to_complete: 20,
      concept_name: "Contextos",
      concept_color: '#0101DF',
      concept_id: 2,
      concept_media_item_id: concept_2_media_item_id,
      concept_rank: 20,
      rank: 2,
      concept_is_assessment: 0,
      lesson_name: "Lesson 1",
      activity_id: activity.id
    )
  end

  let(:completed_assignment) do
    double(
      'Assignment',
      status_code: AttemptStatus::CODE_COMPLETED,
      minutes_to_complete: 15,
      concept_name: "Contextos",
      concept_color: '#0101DF',
      concept_id: 1,
      concept_media_item_id: concept_1_media_item_id,
      lesson_name: "Lesson 1",
      concept_rank: 10,
      rank: 1,
      concept_is_assessment: 0,
      assignable_id: activity.id,
      student_title: 'student title 1'
    )
  end

  before do
    allow(described_class::AssignmentGroup).to receive(:new).and_return(mock_assignment_group)
    allow(mock_assignment_group).to receive(:<<)
    allow(mock_assignment_group).to receive(:incomplete?)
    allow(mock_assignment_group).to receive(:concept_id).and_return(1)
    allow(subject).to receive(:query_builder).and_return(mock_query_builder)
  end

  describe '#assignment_groups' do
    let(:activity) { build_stubbed(:activity) }
    let(:section) { build_stubbed(:section) }

    context "when assignment's concept_id is not the same as the last one added" do
      it 'creates a new assignment group, specifying the assignment concept' do
        expect(described_class::AssignmentGroup).to receive(:new)
          .with(
            concept_label: completed_assignment.concept_name,
            concept_color: completed_assignment.concept_color,
            concept_id: completed_assignment.concept_id,
            concept_media_item_id: concept_1_media_item_id,
            lesson_name: "Lesson 1",
            section_id: section.id,
            is_assessment: (completed_assignment.concept_is_assessment == 1),
            assessment_id: activity.id,
            student_title: completed_assignment.student_title
        ).and_return(mock_assignment_group)

        subject.assignment_groups
      end
    end

    context 'when an assignment group exists' do
      let(:completed_assignment_2) do
        double(
          'Assignment',
          status_code: AttemptStatus::CODE_COMPLETED,
          minutes_to_complete: 15,
          concept_name: "Contextos",
          concept_color: '#0101DF',
          concept_id: 1,
          concept_media_item_id: concept_1_media_item_id,
          lesson_name: "Lesson 1",
          concept_rank: 10,
          rank: 1,
          concept_is_assessment: 0,
          assignable_id: activity.id,
          section_id: section.id,
          student_title: 'student title 2'
        )
      end

      let(:completed_assignments) { [
        completed_assignment,
        completed_assignment_2
      ] }

      before do
        allow(mock_query_builder).to receive(:assignments_for)
          .and_return(completed_assignments)
      end

      context "when assignment's concept_id is the same as the last one added" do
        it 'does not create a new assignment group' do
          expect(described_class::AssignmentGroup).to receive(:new)
            .once.with(
              concept_label: completed_assignment.concept_name,
              concept_color: completed_assignment.concept_color,
              lesson_name: completed_assignment.lesson_name,
              concept_id: completed_assignment.concept_id,
              concept_media_item_id: concept_1_media_item_id,
              section_id: section.id,
              is_assessment: (completed_assignment.concept_is_assessment == 1),
              assessment_id: activity.id,
              student_title: completed_assignment.student_title
          ).and_return(mock_assignment_group)

          subject.assignment_groups
        end
      end

      context 'when assignment is an assessment' do
        it 'creates a new assignment group for each assignment' do
          completed_assignments.each do |assignment|
            allow(assignment).to receive(:concept_is_assessment).and_return(1)
          end

          expect(described_class::AssignmentGroup).to receive(:new).twice

          subject.assignment_groups
        end
      end
    end

    it 'appends the assignment to the last created assignment group' do
      expect(mock_assignment_group).to receive(:<<).with(completed_assignment)

      subject.assignment_groups
    end

    it 'returns an array of assignment groups'  do
      # we need to "unstub" and get AssignmentGroup to return a real object just for this test.
      allow(described_class::AssignmentGroup).to receive(:new).and_call_original

      expect(subject.assignment_groups).to be_a(Array)
      expect(subject.assignment_groups.first).to be_a(described_class::AssignmentGroup)
    end
  end
end

describe DueDate::AssignmentGroup do
  let(:section) { build_stubbed(:section) }
  let(:assessment_id) { 789 }
  let(:included_activity_id) { 102 }
  let(:concept_id) { 4564 }
  let(:subject) do
    described_class.new(
      section_id: section.id,
      included_activity_id: 102,
      concept_id: concept_id
    )
  end
  let(:completed_assignment) do
    double(
      'Assignment',
      status_code: AttemptStatus::CODE_COMPLETED,
      minutes_to_complete: 15,
      rank: 1
    )
  end
  let(:noncompleted_assignment) do
    double(
      'Assignment',
      status_code: AttemptStatus::CODE_OPENED,
      minutes_to_complete: 20,
      rank: 2
    )
  end

  it 'initializes completed_count and assigned_count to zero' do
    expect(subject.completed_count).to eq(0)
    expect(subject.assigned_count).to eq(0)
  end

  describe '#status' do
    it 'returns "not started" if completed_count is zero' do
      subject.completed_count = 0
      expect(subject.status).to eq('not started')
    end

    it 'returns "partial" if completed_count is less than assigned_count' do
      subject.assigned_count = 6
      subject.completed_count = 5
      expect(subject.status).to eq('partial')
    end

    it 'returns "complete" if completed_count is equal to assigned_count' do
      subject.assigned_count = 6
      subject.completed_count = 6
      expect(subject.status).to eq('complete')
    end
  end

  describe '#<<' do
    context 'when a completed assignment is added' do
      before do
        subject << completed_assignment
      end

      it 'increments assigned_count' do
        expect(subject.assigned_count).to eq(1)
      end

      it 'increments completed_count' do
        expect(subject.completed_count).to eq(1)
      end
    end

    context 'when a non completed assignment is added' do
      before do
        subject << noncompleted_assignment
      end

      it 'increments assigned_count' do
        expect(subject.assigned_count).to eq(1)
      end

      it 'does not increment completed_count' do
        expect(subject.completed_count).to eq(0)
      end
    end
  end

  describe '#incomplete_count' do
    it 'returns the difference between assigned count and completed count' do
      subject << completed_assignment
      subject << noncompleted_assignment

      expect(subject.incomplete_count).to eq(1)
    end
  end

  describe '#serialize' do
    it 'includes the status' do
      subject.assigned_count = subject.completed_count = 1
      expect(subject.serialize[:status]).to eq('complete')
    end

    it 'includes the concept label' do
      expected_concept_label = subject.concept_label = 'Cotextos'
      expect(subject.serialize[:title]).to eq(expected_concept_label)
    end

    it 'includes the concept color' do
      expected_concept_color = subject.concept_color = '#0101DF'
      expect(subject.serialize[:color]).to eq(expected_concept_color)
    end
  end
end


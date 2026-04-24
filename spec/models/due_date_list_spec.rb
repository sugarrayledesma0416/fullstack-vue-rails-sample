describe DueDateList do
  let(:user) { create(:student) }
  let(:section) { create(:section) }

  describe '#first_incomplete_past_due_date' do
    it 'returns the first incomplete past due date' do
      summary_1 = instance_double('summary', due_date: 1.day.ago.to_date, incomplete?: false)
      summary_2 = instance_double('summary', due_date: 2.days.ago.to_date, incomplete?: true)
      summary_3 = instance_double('summary', due_date: 3.days.ago.to_date, incomplete?: false)

      due_date_list = described_class.new(user, section)
      allow(due_date_list).to receive(:past_assignment_summaries).and_return(
        [
          summary_1,
          summary_2,
          summary_3
        ]
      )

      expect(due_date_list.first_incomplete_past_due_date).to eql(summary_2.due_date)
    end
  end

  describe '#first_incomplete_future_due_date' do
    it 'returns the first incomplete future due date' do
      summary_1 = instance_double(
        'summary',
        due_date: 1.day.from_now.to_date,
        incomplete?: false
      )
      summary_2 = instance_double(
        'summary',
        due_date: 2.days.from_now.to_date,
        incomplete?: true
      )
      summary_3 = instance_double(
        'summary',
        due_date: 3.days.from_now.to_date,
        incomplete?: false
      )

      due_date_list = described_class.new(user, section)
      allow(due_date_list).to receive(:future_assignment_summaries).and_return(
        [
          summary_1,
          summary_2,
          summary_3
        ]
      )

      expect(due_date_list.first_incomplete_future_due_date).to eql(summary_2.due_date)
    end
  end

  describe '#first_incomplete_past_due_date?' do
    it 'returns true when summary due date is same as the first incomplete past due date' do
      summary = instance_double(
        'summary',
        due_date: Time.zone.today
      )
      due_date_list = described_class.new(user, section)
      allow(due_date_list).to receive(:first_incomplete_past_due_date).and_return(Time.zone.today)
      expect(due_date_list.first_incomplete_past_due_date?(summary)).to be_truthy
    end

    it 'returns false when summary due date is not same as the first incomplete past due date' do
      summary = instance_double('summary', due_date: Time.zone.today)
      due_date_list = described_class.new(user, section)
      allow(due_date_list).to receive(:first_incomplete_past_due_date).and_return(1.day.ago)
      expect(due_date_list.first_incomplete_past_due_date?(summary)).to be_falsey
    end
  end

  describe '#first_incomplete_future_due_date?' do
    it 'returns true when summary due date is same as the first incomplete future due date' do
      summary = instance_double('summary', due_date: Time.zone.today)
      due_date_list = described_class.new(user, section)
      allow(due_date_list).to receive(:first_incomplete_future_due_date).and_return(Time.zone.today)
      expect(due_date_list.first_incomplete_future_due_date?(summary)).to be_truthy
    end

    it 'returns false when summary due date is not same as the first incomplete future due date' do
      summary = instance_double('summary', due_date: Time.zone.today)
      due_date_list = described_class.new(user, section)
      allow(due_date_list).to receive(:first_incomplete_future_due_date).and_return(1.day.ago)
      expect(due_date_list.first_incomplete_future_due_date?(summary)).to be_falsey
    end
  end

  describe '#incomplete_due_dates_count' do
    it 'return the number of due dates with incomplete activities' do
      due_date_list = described_class.new(user, section)
      summary_1 = instance_double('summary', activities_remaining: 10)
      summary_2 = instance_double('summary', activities_remaining: 0)
      summary_3 = instance_double('summary', activities_remaining: 2)
      allow(due_date_list).to receive(:past_assignment_summaries).and_return(
        [
          summary_1,
          summary_2,
          summary_3
        ]
      )
      expect(due_date_list.incomplete_due_dates_count).to eq(2)
    end
  end
end

describe DueDateList::AssignmentSummary do
  before do
    assignment = double(
      Assignment,
      due_date: Date.new(2015, 4, 1),
      time_remaining: 90,
      assignment_count: 2,
      activities_completed: 1
    )

    @assignment_summary = assignment.extend(described_class).extend(ApplicationHelper)
  end

  describe '#formatted_due_date' do
    it 'returns the due date in MM/DD/YY format' do
      expect(@assignment_summary.formatted_due_date).to eq('04/01/15')
    end
  end

  describe '#day_name' do
    it 'returns the day of the week of the due date' do
      expect(@assignment_summary.day_name).to eq('Wednesday')
    end
  end

  describe '#month_name' do
    it 'returns the month name of the due date' do
      expect(@assignment_summary.month_name).to eq('April')
    end
  end

  describe '#month_name_abbrev' do
    it 'returns the abbreviated & capitalized month name of the due date' do
      expect(@assignment_summary.month_name_abbrev).to eq('APR')
    end
  end

  describe '#day' do
    it 'returns the day number of the due date' do
      expect(@assignment_summary.day).to eq('01')
    end
  end

  describe '#day_short' do
    it 'returns the day number of the due date without leading zeroes' do
      expect(@assignment_summary.day_short.strip).to eq('1')
    end
  end

  describe '#estimated_completion_time' do
    it 'returns the time remaining formatted as hours and minutes' do
      expect(@assignment_summary.estimated_completion_time).to eq('1h 30m')
    end
  end

  describe '#activities_remaining' do
    it 'returns the number of activities remaining on the due date' do
      expect(@assignment_summary.activities_remaining).to eq(1)
    end
  end

  describe '#percentage_complete' do
    it 'returns the percentage of activities completed on the due date' do
      expect(@assignment_summary.percentage_complete).to eq(50)
    end
  end

  describe '.by_student_and_section' do
    let(:user) { create(:user) }
    let(:section) { create(:section) }
    let(:activity_1)  { create(:activity, minutes_to_complete: 5) }
    let(:activity_2)  { create(:activity, minutes_to_complete: 3) }
    let(:activity_3)  { create(:activity, minutes_to_complete: 1) }
    let(:due_date_1)  { section.course.start_date + 30.days }
    let(:due_date_2)  { due_date_1 + 4.days }

    before do
      # attempts for section 0
      create(:attempt_completed, activity_id: activity_1.id, user_id: user.id, section_id: 0)
      create(:attempt_submitted, activity_id: activity_2.id, user_id: user.id, section_id: 0)
      # attempts for enrolled section
      create(:attempt_reset, activity_id: activity_1.id, user_id: user.id, section_id: section.id)
      # activity_1 reset and re-attempted
      create(
        :attempt_completed,
        activity_id: activity_1.id,
        user_id: user.id,
        section_id: section.id
      )
      # activity_2 submitted once
      create(
        :attempt_submitted,
        activity_id: activity_2.id,
        user_id: user.id,
        section_id: section.id
      )
      # no attempt for activity_3

      create(:assignment, assignable: activity_1, due_date: due_date_1, section: section)
      create(:assignment, assignable: activity_2, due_date: due_date_1, section: section)
      create(:assignment, assignable: activity_3, due_date: due_date_2, section: section)
    end

    it 'returns a breakdown of completed assignments and total time remaining by due date' do
      results = described_class.by_student_and_section(user.id, section)
      day_1, day_2 = results

      expect(day_1).to be_a_kind_of(described_class)

      expect(day_1.due_date).to eq(due_date_1)
      expect(day_1.assignment_count).to eq(2)
      # activities_completed count includes attempts submitted
      expect(day_1.activities_completed).to eq(2)
      expect(day_1.time_remaining).to eq(3)

      expect(day_2.due_date).to eq(due_date_2)
      expect(day_2.assignment_count).to eq(1)
      expect(day_2.activities_completed).to eq(0)
      expect(day_2.time_remaining).to eq(1)
    end

    context 'when some activities are assigned individually,' do
      it 'includes only the activities assigned to all students or the ' \
         'current student' do
        Assignment.find_by(assignable_id: activity_1.id).update!(
          individually_assignable: false
        )

        # individually assigned to current student
        Assignment.find_by(assignable_id: activity_2.id).update!(
          individually_assignable: true
        )

        IndividualAssignment.create!(
          activity_id: activity_2.id,
          section_id: section.id,
          user_id: user.id
        )

        # individually assigned, but not to current student
        Assignment.find_by(assignable_id: activity_3).update!(
          due_date: due_date_1, individually_assignable: true
        )

        results = described_class.by_student_and_section(user.id, section).first
        expect(results.assignment_count).to eq(2)
      end
    end

    context 'when some activities are assigned with individual due dates,' do
      it 'groups activities sharing a given due date when assigned to ' \
         'all students, assigned to the current student with no individual ' \
         'due date, or to the current student with an individual due date ' \
         'matching the given due date' do
        # Not individually assigned
        Assignment.find_by(assignable_id: activity_1.id).update!(
          individually_assignable: false
        )

        # individually assigned to current student, no individual due date
        Assignment.find_by(assignable_id: activity_2.id).update!(
          individually_assignable: true
        )

        IndividualAssignment.create!(
          activity_id: activity_2.id,
          section_id: section.id,
          user_id: user.id
        )

        # individually assigned to current student, individual due date
        # matching the date of the other assignments
        individual_assignment_matching_due_date = create(
          :assignment,
          due_date: due_date_2,
          individually_assignable: true,
          section_id: section.id
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_matching_due_date.assignable_id,
          due_date: due_date_1,
          section_id: section.id,
          user_id: user.id
        )

        # individually assigned to current student, individual due date
        # different from that of the other assignments
        individual_assignment_non_matching_due_date = create(
          :assignment,
          due_date: due_date_2 + 3,
          individually_assignable: true,
          section_id: section.id
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_non_matching_due_date.assignable_id,
          due_date: due_date_2 + 2,
          section_id: section.id,
          user_id: user.id
        )

        # individually assigned, but not to current student
        other_student_assignment = create(
          :assignment,
          due_date: due_date_2,
          individually_assignable: true,
          section_id: section.id
        )

        IndividualAssignment.create!(
          activity_id: other_student_assignment.assignable_id,
          due_date: due_date_1,
          section_id: section.id,
          user_id: create(:student).id
        )

        results = described_class.by_student_and_section(user.id, section).first
        expect(results.assignment_count).to eq(3)

        # Verify correct field retrieved via SELECT statement
        expect(results.due_date).to eq(due_date_1)
      end
    end

    context 'when days_to_show_assignment_due_date is set on section,' do
      let(:due_days_limit) { 2 }
      let(:current_due_day) { Time.zone.today }
      let(:due_date_1) { current_due_day }
      let(:due_date_2) { current_due_day + due_days_limit.days }
      let(:due_date_3) { current_due_day + due_days_limit.days + 2.days }
      let(:section_with_release_date) do
        create(:section, days_to_show_assignment_due_date: due_days_limit)
      end
      let(:section_without_release_date) { create(:section) }

      before do
        # Assignments for which release due date is set
        create(:assignment, due_date: due_date_1, section: section_with_release_date)
        create(:assignment, due_date: due_date_2, section: section_with_release_date)
        create(:assignment, due_date: due_date_3, section: section_with_release_date)
        # Assignments for which release due date is not set
        create(:assignment, due_date: due_date_1, section: section_without_release_date)
        create(:assignment, due_date: due_date_2, section: section_without_release_date)
        create(:assignment, due_date: due_date_3, section: section_without_release_date)
      end

      it 'returns only due dates that are released to student when release' \
         ' date is set in section' do
        released_due_dates = described_class.by_student_and_section(
          user.id,
          section_with_release_date
        ).map(&:due_date)

        expect(released_due_dates).to eq([due_date_1, due_date_2])
      end

      it 'returns all due dates when release date is not set in section' do
        released_due_dates = described_class.by_student_and_section(
          user.id,
          section_without_release_date
        ).map(&:due_date)
        expect(released_due_dates).to eq([due_date_1, due_date_2, due_date_3])
      end

      it 'shows assignments with their release date based off the ' \
         'individual due date when assigned with individual due dates' do
        assignments = section_with_release_date.assignments.to_a

        IndividualAssignment.create!(
          activity_id: assignments[2].assignable_id,
          due_date: due_date_1,
          section_id: section_with_release_date.id,
          user_id: user.id
        )

        IndividualAssignment.create!(
          activity_id: assignments[0].assignable_id,
          due_date: due_date_3,
          section_id: section_with_release_date.id,
          user_id: user.id
        )

        released_due_dates = described_class.by_student_and_section(
          user.id,
          section_with_release_date
        ).map(&:due_date)
        expect(released_due_dates).to eq([due_date_1, due_date_2])
      end
    end
  end
end

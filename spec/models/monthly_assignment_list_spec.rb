describe MonthlyAssignmentList do
  describe '.assignments' do
    # base date within the month to avoid end_of_month failures
    let(:due_date) { Date.today.beginning_of_month + 37.days }
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, end_date: 14.months.from_now) }
    let(:section_1) { create(:section, course: course) }

    context 'when only one section is specified,' do
      let(:list) do
        described_class.new(due_date.month, due_date.year, [section_1], instructor)
      end

      it 'returns only assignemnts assigned for that section within the ' \
         'specified month' do
        assignment = create(:assignment, due_date: due_date, section: section_1)
        create(:assignment, due_date: due_date, section: create(:section))
        create(:assignment, due_date: due_date.prev_month, section: section_1)
        create(:assignment, due_date: due_date.next_month, section: section_1)

        expect(
          list.assignments.values.flat_map(&:id)
        ).to contain_exactly(assignment.id)
      end

      it 'groups assignments by due date' do
        create(:assignment, due_date: due_date, section: section_1)

        other_due_date = due_date + 1.day
        create(
          :assignment,
          due_date: other_due_date,
          section: section_1
        )

        expect(list.assignments.keys).to contain_exactly(
          due_date, other_due_date
        )
      end

      it 'does not fetch assignments that are assigned in the same ' \
         'month of different years' do
        create(:assignment, due_date: due_date, section: section_1)
        same_month_different_year = due_date + 12.months

        create(:assignment, due_date: same_month_different_year, section: section_1)

        expect(list.assignments.keys).to contain_exactly(due_date)
      end

      it 'exposes an activity_count attribute on the assignment for each ' \
         'due date with the total number of assignments on that day' do
        create(:assignment, due_date: due_date, section: section_1)
        create(:assignment, due_date: due_date, section: section_1)

        expect(list.assignments[due_date].activity_count).to eq(2)
      end

      it 'sums the minutes to complete each assigned activity if specified' do
        create(
          :assignment,
          assignable: create(:activity, minutes_to_complete: 11),
          due_date: due_date,
          section: section_1
        )
        create(
          :assignment,
          assignable: create(:activity, minutes_to_complete: 31),
          due_date: due_date,
          section: section_1
        )

        expect(list.assignments[due_date].total_time).to eq(42)
      end

      it 'uses a default value of 10 minutes_to_complete if assigned ' \
         'activities have a nil minutes_to_complete value' do
        create(
          :assignment,
          assignable: create(:activity, minutes_to_complete: nil),
          due_date: due_date,
          section: section_1
        )
        create(
          :assignment,
          assignable: create(:activity, minutes_to_complete: nil),
          due_date: due_date,
          section: section_1
        )

        expect(list.assignments[due_date].total_time).to eq(20)
      end
    end

    context 'with more than one section,' do
      let(:activity_1) { create(:activity, minutes_to_complete: 22) }
      let(:activity_2) { create(:activity, minutes_to_complete: 53) }
      let(:section_2) { create(:section, course: course) }

      let(:list) do
        described_class.new(
          due_date.month,
          due_date.year,
          [section_1, section_2],
          instructor
        )
      end

      before do
        create(
          :assignment,
          assignable: activity_1, due_date: due_date, section: section_1
        )
        create(
          :assignment,
          assignable: activity_2, due_date: due_date, section: section_1
        )
        create(
          :assignment,
          assignable: activity_1, due_date: due_date, section: section_2
        )
        create(
          :assignment,
          assignable: activity_2, due_date: due_date, section: section_2
        )
      end

      it 'returns the correct total time for each activity' do
        expect(list.assignments[due_date].total_time).to eq(75)
      end

      it 'returns the correct activity count' do
        expect(list.assignments[due_date].activity_count).to eq(2)
      end
    end

    context 'when the current user is a student,' do
      let(:student) { create(:student) }

      let(:list) do
        described_class.new(due_date.month, due_date.year, [section_1], student)
      end

      context 'when there are individually-assignable assignments,' do
        let(:activity) { create(:activity) }

        before do
          create(
            :assignment,
            assignable: activity,
            due_date: due_date,
            individually_assignable: true,
            section: section_1
          )
        end

        it 'does not return individually-assignable grades if they are not ' \
           'assigned to the student' do
          expect(list.assignments).to be_empty
        end

        it 'returns individually-assignable grades if they are assigned ' \
           'to the student' do
          IndividualAssignment.create!(
            activity_id: activity.id,
            section_id: section_1.id,
            user_id: student.id
          )
          expect(list.assignments[due_date].activity_count).to eq(1)
        end

        it 'returns an assignment with a custom due date in given month/year' do
          IndividualAssignment.create!(
            activity_id: activity.id,
            due_date: due_date.end_of_month,
            section_id: section_1.id,
            user_id: student.id
          )
          expect(list.assignments[due_date.end_of_month].activity_count).to eq(1)
        end

        it 'does not return an assignment with a custom due date not in given month/year' do
          IndividualAssignment.create!(
            activity_id: activity.id,
            due_date: due_date.end_of_month + 1.day,
            section_id: section_1.id,
            user_id: student.id
          )
          expect(list.assignments).to be_empty
        end

        it 'correctly groups assignments with due dates in same month' do
          create(:assignment, due_date: due_date, section: section_1)
          create(:assignment, due_date: due_date, section: section_1)
          IndividualAssignment.create!(
            activity_id: activity.id,
            due_date: due_date + 7.days,
            section_id: section_1.id,
            user_id: student.id
          )

          expected_counts_and_times = [[2, 20], [1, 10]]

          actual_counts_and_times = [due_date, due_date + 7.days].map do |day|
            assignment_group = list.assignments[day]
            [assignment_group.activity_count, assignment_group.total_time]
          end

          expect(actual_counts_and_times).to eq(expected_counts_and_times)
        end
      end

      context 'when the section does not restrict days to show assignments,' do
        it 'returns all assignments for the month regardless of the due date' do
          create(:assignment, due_date: due_date, section: section_1)

          other_due_date = due_date + 1.day
          create(
            :assignment,
            due_date: other_due_date,
            section: section_1
          )

          expect(list.assignments.keys).to contain_exactly(
            due_date, other_due_date
          )
        end
      end

      context 'when the section restricts days to show assignments,' do
        before do
          range = (due_date + 7.days - Date.today)
          section_1.update!(days_to_show_assignment_due_date: range)
        end

        it 'shows assignments due inside the release range' do
          date_inside_range = (due_date + 5.days)
          create(:assignment, due_date: date_inside_range, section: section_1)

          expect(list.assignments.keys).to contain_exactly(date_inside_range)
        end

        it 'does not show assignments due outside the release range' do
          create(:assignment, due_date: due_date + 9.days, section: section_1)

          expect(list.assignments.keys).to be_empty
        end
      end
    end
  end
end

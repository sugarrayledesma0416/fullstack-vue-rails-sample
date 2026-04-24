describe ClassworkFilter do
  let(:section) { create(:section) }
  let(:student) { create(:student) }
  let(:assignment_day) { '2014-03-27' }
  let(:concept) { create(:concept) }
  let(:category) { create(:category) }
  let(:classwork) { Classwork.new(student, section) }

  describe '#assignments' do
    context 'when initialized for overdue assignments,' do
      let(:lesson_1) { create(:lesson) }
      let(:lesson_2) { create(:lesson) }
      let(:activity_1) { create(:activity, lesson: lesson_1) }
      let(:activity_2) { create(:activity, lesson: lesson_2) }
      let(:activity_3) { create(:activity, lesson: lesson_2) }
      let(:due_date) { 2.days.ago }

      let!(:assignment_1) do
        create(
          :assignment,
          assignable: activity_1,
          due_date: due_date,
          section: section
        )
      end

      let!(:assignment_2) do
        create(
          :assignment,
          assignable: activity_2,
          due_date: due_date,
          section: section
        )
      end
      let(:other_section) { create(:section) }

      let(:classwork_filter) do
        described_class.new(assignment_day: 'overdue', classwork: classwork)
      end

      it 'returns assignments for the specified section if no attempt ' \
         'exists for the specified user' do
        # completed attempt by different user
        create(
          :attempt_completed,
          activity: activity_1,
          section: section,
          user: create(:student)
        )

        # completed attempt by current user, but in a different section
        create(
          :attempt_completed,
          activity: activity_2,
          section: other_section,
          user: student
        )

        # assignment in different section
        create(
          :assignment,
          assignable: activity_3,
          due_date: 2.days.ago,
          section: other_section
        )

        expect(classwork_filter.assignments).to contain_exactly(
          assignment_1, assignment_2
        )
      end

      it 'does not return assignments with a future due date' do
        create(
          :assignment,
          assignable: activity_3,
          due_date: 2.days.from_now,
          section: section
        )

        expect(classwork_filter.assignments).to contain_exactly(
          assignment_1, assignment_2
        )
      end

      it 'does not return past-due assignments when there are submitted ' \
         'or completed attempts for the current user and section' do
        create(
          :attempt_completed,
          activity: activity_1,
          section: section,
          user: student
        )
        create(
          :attempt_submitted,
          activity: activity_2,
          section: section,
          user: student
        )

        expect(classwork_filter.assignments).to eq([])
      end

      it 'returns past due assignments when there are opened or reset ' \
         'attempts for the current user and section' do
        create(
          :attempt_opened,
          activity: activity_1,
          section: section,
          user: student
        )
        create(
          :attempt_reset,
          activity: activity_2,
          section: section,
          user: student
        )

        expect(classwork_filter.assignments).to contain_exactly(
          assignment_1, assignment_2
        )
      end

      it 'does not return assignments for which the current student has an ' \
         'attempt that was reset, but subsequently completed' do
        create(
          :attempt_reset,
          activity: activity_1,
          section: section,
          user: student
        )
        # subsequent completed attempt
        create(
          :attempt_completed,
          activity: activity_1,
          section: section,
          user: student
        )

        expect(classwork_filter.assignments).to eq([assignment_2])
      end

      it 'returns past due assignments for activities from all lessons ' \
         'when no lesson_id is specified' do
        classwork_filter = described_class.new(
          assignment_day: 'overdue',
          classwork: classwork,
          lesson_id: nil
        )

        expect(classwork_filter.assignments).to contain_exactly(
          assignment_1, assignment_2
        )
      end

      context 'when some activities are assigned individually,' do
        it 'includes only the activities assigned to all students or the ' \
           'current student' do
          # assigned to all students
          assignment_1.update!(individually_assignable: false)

          # individually assigned to current student
          assignment_2.update!(individually_assignable: true)

          IndividualAssignment.create!(
            activity_id: assignment_2.assignable_id,
            section_id: section.id,
            user_id: student.id
          )

          # individually assigned, but not to current student
          create(
            :assignment,
            assignable: activity_3,
            due_date: 2.days.ago,
            individually_assignable: true,
            section: section
          )

          expect(classwork_filter.assignments).to contain_exactly(
            assignment_1, assignment_2
          )
        end
      end

      context 'when some activities are assigned with individual due dates,' do
        let(:other_due_date) { 2.days.from_now.to_date }

        it 'includes only the activities assigned to all students or the ' \
           'current student with no individual due date, or the current ' \
           'student with an individual due date in the past' do
          # assigned to all students
          assignment_1.update!(individually_assignable: false)

          # individually assigned to current student, no individual due date
          assignment_2.update!(individually_assignable: true)

          IndividualAssignment.create!(
            activity_id: assignment_2.assignable_id,
            section_id: section.id,
            user_id: student.id
          )

          # individually assigned to current student, individual due date
          # matching specified date
          individual_assignment_matching_due_date = create(
            :assignment,
            due_date: other_due_date,
            individually_assignable: true,
            section_id: section.id
          )

          IndividualAssignment.create!(
            activity_id: individual_assignment_matching_due_date.assignable_id,
            due_date: due_date,
            section_id: section.id,
            user_id: student.id
          )

          # individually assigned to current student, individual due date
          # different from specified date
          individual_assignment_non_matching_due_date = create(
            :assignment,
            due_date: due_date,
            individually_assignable: true,
            section_id: section.id
          )

          IndividualAssignment.create!(
            activity_id: individual_assignment_non_matching_due_date.assignable_id,
            due_date: other_due_date,
            section_id: section.id,
            user_id: student.id
          )

          # individually assigned, but not to current student
          other_student_assignment = create(
            :assignment,
            due_date: other_due_date,
            individually_assignable: true,
            section_id: section.id
          )

          IndividualAssignment.create!(
            activity_id: other_student_assignment.assignable_id,
            due_date: due_date,
            section_id: section.id,
            user_id: create(:student).id
          )

          expect(classwork_filter.assignments).to contain_exactly(
            assignment_1,
            assignment_2,
            individual_assignment_matching_due_date
          )
        end
      end

      it 'returns only past due assignments for activities from the specified ' \
         'lesson when a lesson_id is specified' do
        classwork_filter = described_class.new(
          assignment_day: 'overdue',
          classwork: classwork,
          lesson_id: lesson_1.id
        )

        expect(classwork_filter.assignments).to eq([assignment_1])
      end
    end

    context 'when initialized for all assignments' do
      it 'returns all the assignments for the given date,' do
        classwork_filter = described_class.new(
          assignment_day: assignment_day,
          category: category,
          classwork: classwork,
          concept: concept,
          include_all_assignments: true
        )

        expect(classwork).to receive(:all_assignments_for_date)
          .with(assignment_day, concept, category)
          .and_return('all_assignments')

        expect(classwork_filter.assignments).to eq('all_assignments')
      end
    end

    context 'when is not given a specific filter option' do
      it 'returns the incomplete assignments for the given date' do
        classwork_filter = described_class.new(
          assignment_day: assignment_day,
          category: category,
          classwork: classwork,
          concept: concept
        )

        expect(classwork_filter).to receive(:incomplete_assignments_for_date)
          .with(assignment_day, concept, category)
          .and_return('incomplete_assignments')

        expect(classwork_filter.assignments).to eq('incomplete_assignments')
      end
    end

    context 'when a range is given,' do
      context 'when no concept is given,' do
        it 'returns an empty array' do
          classwork_filter = described_class.new(
            category: category,
            classwork: classwork,
            rank_range: '1..2'
          )
          expect(classwork_filter.assignments).to eq([])
        end
      end

      context 'when a concept is given,' do
        let(:wrong_concept_activity) do
          create(:activity, concept: create(:concept))
        end

        let(:base_activity) { create(:activity, concept: concept) }
        let(:other_activity) { create(:activity, concept: concept) }

        let(:included_assignment) do
          create(
            :assignment,
            assignable: base_activity,
            due_date: Date.today,
            rank: 2,
            section: section
          )
        end

        let(:classwork_filter) do
          described_class.new(
            assignment_day: included_assignment.due_date,
            category: category,
            classwork: classwork,
            concept: concept,
            rank_range: '1..3'
          )
        end

        it 'includes assignments only for specified day' do
          create(
            :assignment,
            assignable: other_activity,
            due_date: included_assignment.due_date - 1,
            rank: 2,
            section: section
          )
          expect(classwork_filter.assignments).to eq([included_assignment])
        end

        it 'includes assignments only for specified section' do
          assignment = create(
            :assignment,
            assignable: other_activity,
            due_date: included_assignment.due_date,
            rank: 2,
            section: create(:section)
          )
          expect(classwork_filter.assignments).to eq([included_assignment])
        end

        it 'includes assignments only for activities in the correct concept' do
          assignment = create(
            :assignment,
            assignable: wrong_concept_activity,
            due_date: included_assignment.due_date,
            rank: 2,
            section: section
          )
          expect(classwork_filter.assignments).to eq([included_assignment])
        end

        it 'includes assignment in the correct rank range' do
          assignment = create(
            :assignment,
            assignable: other_activity,
            due_date: included_assignment.due_date,
            rank: 4,
            section: section
          )
          expect(classwork_filter.assignments).to eq([included_assignment])
        end

        context 'when there are assignment sets with custom ranks' do
          let!(:custom_included_assignment) do
            create(
              :assignment,
              assignable: other_activity,
              due_date: included_assignment.due_date,
              rank: 4,
              section: section
            )
          end

          let(:other_activity_2) { create(:activity, concept: concept) }

          let(:assignment_set_1) do
            create(
              :assignment_set,
              due_date: included_assignment.due_date,
              section: section
            )
          end

          let(:assignment_set_2) do
            create(
              :assignment_set,
              due_date: included_assignment.due_date + 1,
              section: section
            )
          end

          before do
            create(
              :assignment_set_activity,
              activity: base_activity,
              assignment_set: assignment_set_1,
              assignment_set_rank: 4
            )

            create(
              :assignment_set_activity,
              activity: other_activity,
              assignment_set: assignment_set_1,
              assignment_set_rank: 1
            )

            # should not get included in the results
            create(
              :assignment_set_activity,
              activity: other_activity_2,
              assignment_set: assignment_set_2,
              assignment_set_rank: 3
            )
          end

          it 'applies the rank range to the custom ranks instead of ' \
             'the ranks from the assignment record' do
            expect(classwork_filter.assignments).to contain_exactly(
              custom_included_assignment
            )
          end
        end

        context 'when some activities are assigned individually,' do
          let(:classwork_filter) do
            described_class.new(
              assignment_day: Date.tomorrow.to_date,
              category: category,
              classwork: classwork,
              concept: concept,
              rank_range: '1..2'
            )
          end

          it 'includes only the activities assigned to all students or the ' \
             'current student' do
            # assigned to all students, correct concept, correct due date
            assignment_1 = create(
              :assignment,
              assignable: base_activity,
              due_date: Date.tomorrow,
              individually_assignable: false,
              rank: 1,
              section: section
            )

            # assigned to all students, correct concept, wrong due date
            create(
              :assignment,
              assignable: create(:activity, concept: concept),
              due_date: 3.days.from_now,
              individually_assignable: false,
              rank: 1,
              section: section
            )

            # assigned to all students, correct concept, wrong rank
            create(
              :assignment,
              assignable: create(:activity, concept: concept),
              due_date: Date.tomorrow,
              individually_assignable: false,
              rank: 3,
              section: section
            )

            # individually assigned to current student
            assignment_2 = create(
              :assignment,
              assignable: other_activity,
              due_date: Date.tomorrow,
              individually_assignable: true,
              rank: 1,
              section: section
            )

            IndividualAssignment.create!(
              activity_id: other_activity.id,
              section_id: section.id,
              user_id: student.id
            )

            # correct concept, individually assigned, but not to current student
            wrong_student_assignment = create(
              :assignment,
              assignable: create(:activity, concept: concept),
              due_date: Date.tomorrow,
              individually_assignable: true,
              rank: 1,
              section: section
            )

            IndividualAssignment.create!(
              activity_id: wrong_student_assignment.assignable_id,
              section_id: section.id,
              user_id: create(:student).id
            )

            # individually assigned to current student, but wrong concept
            create(
              :assignment,
              assignable: wrong_concept_activity,
              due_date: Date.tomorrow,
              individually_assignable: false,
              rank: 1,
              section: section
            )

            IndividualAssignment.create!(
              activity_id: wrong_concept_activity.id,
              section_id: section.id,
              user_id: student.id
            )

            expect(classwork_filter.assignments).to contain_exactly(
              assignment_1, assignment_2
            )
          end
        end

        context 'when some activities are assigned with individual due dates,' do
          let(:due_date) { 2.days.from_now.to_date }
          let(:other_due_date) { due_date + 1 }

          let(:classwork_filter) do
            described_class.new(
              assignment_day: due_date,
              category: category,
              classwork: classwork,
              concept: concept,
              rank_range: '1..2'
            )
          end

          it 'includes only the activities assigned to all students or the ' \
             'current student with no individual due date, or the current ' \
             'student with an individual due date matching the specified date' do
            # assigned to all students, correct concept, correct due date
            all_students_assignment = create(
              :assignment,
              assignable: base_activity,
              due_date: due_date,
              individually_assignable: false,
              rank: 2,
              section: section
            )

            # assigned to all students, correct concept, wrong due date
            create(
              :assignment,
              assignable: create(:activity, concept: concept),
              due_date: other_due_date,
              individually_assignable: false,
              rank: 1,
              section: section
            )

            # assigned to all students, correct concept, wrong rank
            create(
              :assignment,
              assignable: create(:activity, concept: concept),
              due_date: due_date,
              individually_assignable: false,
              rank: 3,
              section: section
            )

            # individually assigned to current student, no individual due date
            individual_assignment_no_due_date = create(
              :assignment,
              assignable: other_activity,
              due_date: due_date,
              individually_assignable: true,
              rank: 1,
              section: section
            )

            IndividualAssignment.create!(
              activity_id: other_activity.id,
              section_id: section.id,
              user_id: student.id
            )

            # correc concept, individually assigned to current student,
            # individual due date matching specified date
            individual_assignment_matching_due_date = create(
              :assignment,
              assignable: create(:activity, concept: concept),
              due_date: other_due_date,
              individually_assignable: true,
              rank: 1,
              section_id: section.id
            )

            IndividualAssignment.create!(
              activity_id: individual_assignment_matching_due_date.assignable_id,
              due_date: due_date,
              section_id: section.id,
              user_id: student.id
            )

            # correct concept, individually assigned to current student,
            # individual due date different from specified date
            individual_assignment_non_matching_due_date = create(
              :assignment,
              assignable: create(:activity, concept: concept),
              due_date: due_date,
              individually_assignable: true,
              rank: 1,
              section_id: section.id
            )

            IndividualAssignment.create!(
              activity_id: individual_assignment_non_matching_due_date.assignable_id,
              due_date: other_due_date,
              section_id: section.id,
              user_id: student.id
            )

            # correct concept, individually assigned to current student,
            # individual due date matching specified date,
            # wrong rank,
            # custom rank within rank range
            individual_assignment_matching_due_date_custom_rank = create(
              :assignment,
              assignable: create(:activity, concept: concept),
              due_date: other_due_date,
              individually_assignable: true,
              rank: 4,
              section_id: section.id
            )

            IndividualAssignment.create!(
              activity_id: individual_assignment_matching_due_date_custom_rank.assignable_id,
              due_date: due_date,
              section_id: section.id,
              user_id: student.id
            )

            assignment_set = AssignmentSet.create!(
              due_date: other_due_date,
              section_id: section.id
            )

            AssignmentSetActivity.create!(
              activity_id: individual_assignment_matching_due_date_custom_rank.assignable_id,
              assignment_set_id: assignment_set.id,
              assignment_set_rank: 2
            )

            # correct concept, individually assigned, but not to current student
            wrong_student_assignment = create(
              :assignment,
              assignable: create(:activity, concept: concept),
              due_date: other_due_date,
              individually_assignable: true,
              rank: 1,
              section: section
            )

            IndividualAssignment.create!(
              activity_id: wrong_student_assignment.assignable_id,
              due_date: due_date,
              section_id: section.id,
              user_id: create(:student).id
            )

            # individually assigned to current student, but wrong concept
            create(
              :assignment,
              assignable: wrong_concept_activity,
              due_date: other_due_date,
              individually_assignable: false,
              rank: 1,
              section: section
            )

            IndividualAssignment.create!(
              activity_id: wrong_concept_activity.id,
              due_date: due_date,
              section_id: section.id,
              user_id: student.id
            )

            expect(classwork_filter.assignments).to contain_exactly(
              all_students_assignment,
              individual_assignment_no_due_date,
              individual_assignment_matching_due_date,
              individual_assignment_matching_due_date_custom_rank
            )
          end
        end
      end
    end
  end

  describe '#create_workset' do
    let(:assignment_1) { create(:assignment, due_date: Date.tomorrow) }
    let(:assignment_2) { create(:assignment, due_date: Date.today) }
    let(:assignment_3) { create(:assignment, due_date: Date.today, rank: 2) }
    let(:assignment_4) { create(:assignment, due_date: Date.today, rank: 1) }
    let(:classwork_filter) do
      described_class.new(
        assignment_day: assignment_day,
        category: category,
        classwork: classwork,
        concept: concept
      )
    end

    before do
      allow(classwork).to receive(:new_workset)
    end

    context 'when the assignments do not have the same due date,' do
      it 'creates a workset ordered by due date' do
        allow(classwork_filter).to receive(:assignments)
          .and_return(Assignment.where(id: [assignment_1.id, assignment_2.id]))

        classwork_filter.create_workset

        expect(classwork).to have_received(:new_workset).with(
          [assignment_2.assignable.id, assignment_1.assignable.id]
        )
      end
    end

    context 'when the assignments are on the same due date,' do
      context 'with different assignment ranks,' do
        it 'orders them by their ranks' do
          allow(classwork_filter).to receive(:assignments)
            .and_return(Assignment.where(id: [assignment_3.id, assignment_4.id]))

          classwork_filter.create_workset

          expect(classwork).to have_received(:new_workset).with(
            [assignment_4.assignable.id, assignment_3.assignable.id]
          )
        end
      end

      context 'when there are assignment sets with custom ranks' do
        let(:lesson) { create(:lesson) }
        let(:toc_entry) { create(:toc_entry) }

        let(:classwork_filter) do
          described_class.new(
            assignment_day: due_date,
            category: category,
            classwork: classwork,
            concept: concept
          )
        end

        let(:due_date) { section.course.start_date + 7.days }

        let(:activity_1) do
          create(:activity, concept: concept, lesson: lesson)
        end

        let(:activity_2) do
          create(:activity, concept: concept, lesson: lesson)
        end

        let(:activity_3) do
          create(:activity, concept: concept, lesson: lesson)
        end

        let(:assignment_set_1) do
          create(
            :assignment_set,
            due_date: due_date,
            section: section
          )
        end

        let(:assignment_set_2) do
          create(
            :assignment_set,
            due_date: due_date + 1,
            section: section
          )
        end

        before do
          lesson.toc_entries = [toc_entry]
          lesson.save!

          create(
            :assignment,
            assignable: activity_1,
            category: category,
            due_date: due_date,
            rank: 1,
            section: section
          )

          create(
            :assignment,
            assignable: activity_2,
            category: category,
            due_date: due_date,
            rank: 2,
            section: section
          )

          create(
            :assignment_set_activity,
            activity: activity_2,
            assignment_set: assignment_set_1,
            assignment_set_rank: 1
          )

          create(
            :assignment_set_activity,
            activity: activity_1,
            assignment_set: assignment_set_1,
            assignment_set_rank: 2
          )

          # should not get included in the results
          create(
            :assignment_set_activity,
            activity: activity_3,
            assignment_set: assignment_set_2,
            assignment_set_rank: 3
          )

          allow(classwork).to receive(:new_workset)
        end

        it 'returns the activities sorted by the custom rank instead of ' \
           'the rank from the assignment record' do
          classwork_filter.create_workset

          expect(classwork).to have_received(:new_workset).with(
            [activity_2.id, activity_1.id]
          )
        end
      end

      context 'with equal assignment ranks,' do
        let(:due_date) { section.course.start_date + 7.days }
        let(:unit_one) { create(:unit, rank: 3) }
        let(:lesson_one) do
          create(
            :lesson,
            unit: unit_one,
            toc_entries_xml: Nokogiri::XML(
              File.open('spec/fixtures/xml/lesson.xml')
            ).to_xml,
            rank: 3
          )
        end
        let(:concept_one) { create(:concept, lesson: lesson_one, rank: 3) }
        let(:classwork_filter) do
          described_class.new(
            assignment_day: due_date,
            classwork: classwork,
            concept: concept_one
          )
        end

        it 'loads the assignments ordered by unit rank when assignment rank tie' do
          unit_two = create(:unit, rank: 4)
          lesson_two = create(:lesson, unit: unit_two, rank: 1)
          activity_one = create(:activity, lesson: lesson_two)
          activity_two = create(:activity, lesson: lesson_one)
          assignment_one = create(
            :assignment,
            assignable: activity_one,
            section: section,
            due_date: due_date,
            rank: 1
          )
          assignment_two = create(
            :assignment,
            assignable: activity_two,
            section: section,
            due_date: due_date,
            rank: 1
          )
          allow(classwork_filter).to receive(:assignments).and_return(
            Assignment.where(id: [assignment_one.id, assignment_two.id])
          )

          classwork_filter.create_workset

          expect(classwork).to have_received(:new_workset).with(
            [
              assignment_two.assignable.id,
              assignment_one.assignable.id
            ]
          )
        end

        it 'loads the assignments ordered by lesson rank when assignment rank and unit rank tie' do
          lesson_two = create(:lesson, unit: unit_one, rank: 4)
          activity_one = create(:activity, lesson: lesson_two)
          activity_two = create(:activity, lesson: lesson_one)
          assignment_one = create(
            :assignment,
            assignable: activity_one,
            section: section,
            due_date: due_date,
            rank: 1
          )
          assignment_two = create(
            :assignment,
            assignable: activity_two,
            section: section,
            due_date: due_date,
            rank: 1
          )
          allow(classwork_filter).to receive(:assignments).and_return(
            Assignment.where(id: [assignment_one.id, assignment_two.id])
          )

          classwork_filter.create_workset

          expect(classwork).to have_received(:new_workset).with(
            [
              assignment_two.assignable.id,
              assignment_one.assignable.id
            ]
          )
        end

        it 'loads the assignments ordered by concept rank when assignment rank, unit rank ' \
           'and lesson rank tie' do
          concept_two = create(:concept, lesson: lesson_one, rank: 4)
          activity_one = create(:activity, lesson: lesson_one, concept: concept_two)
          activity_two = create(:activity, lesson: lesson_one, concept: concept_one)
          assignment_one = create(
            :assignment,
            assignable: activity_one,
            section: section,
            due_date: due_date,
            rank: 1
          )
          assignment_two = create(
            :assignment,
            assignable: activity_two,
            section: section,
            due_date: due_date,
            rank: 1
          )
          allow(classwork_filter).to receive(:assignments).and_return(
            Assignment.where(id: [assignment_one.id, assignment_two.id])
          )

          classwork_filter.create_workset

          expect(classwork).to have_received(:new_workset).with(
            [
              assignment_one.assignable.id,
              assignment_two.assignable.id
            ]
          )
        end

        it 'loads the assignments ordered by activity concept_rank when assignment rank, unit rank, ' \
           'lesson rank and concept rank tie' do
          activity_one = create(
            :activity,
            lesson: lesson_one,
            concept: concept_one,
            concept_rank: 3
          )
          activity_two = create(
            :activity,
            lesson: lesson_one,
            concept: concept_one,
            concept_rank: 2
          )
          assignment_one = create(
            :assignment,
            assignable: activity_one,
            section: section,
            due_date: due_date,
            rank: 1
          )
          assignment_two = create(
            :assignment,
            assignable: activity_two,
            section: section,
            due_date: due_date,
            rank: 1
          )
          allow(classwork_filter).to receive(:assignments).and_return(
            Assignment.where(id: [assignment_one.id, assignment_two.id])
          )

          classwork_filter.create_workset

          expect(classwork).to have_received(:new_workset).with(
            [
              assignment_one.assignable.id,
              assignment_two.assignable.id
            ]
          )
        end

        it 'loads the assignments ordered by activity toc_location_rank when assignment rank, ' \
           'unit rank, lesson rank, concept rank and activity concept_rank tie' do
          activity_one = create(
            :activity,
            lesson: lesson_one,
            concept: concept_one,
            concept_rank: 1,
            toc_location_rank: 3
          )
          activity_two = create(
            :activity,
            lesson: lesson_one,
            concept: concept_one,
            concept_rank: 1,
            toc_location_rank: 2
          )
          assignment_one = create(
            :assignment,
            assignable: activity_one,
            section: section,
            due_date: due_date,
            rank: 1
          )
          assignment_two = create(
            :assignment,
            assignable: activity_two,
            section: section,
            due_date: due_date,
            rank: 1
          )
          allow(classwork_filter).to receive(:assignments).and_return(
            Assignment.where(id: [assignment_one.id, assignment_two.id])
          )

          classwork_filter.create_workset

          expect(classwork).to have_received(:new_workset).with(
            [
              assignment_two.assignable.id,
              assignment_one.assignable.id
            ]
          )
        end
      end
    end

    it 'creates a workset that includes assessments when concept is specified' do
      activity = create(:activity)
      activity.concept.assessment = true
      activity.concept.save!

      assignment_5 = create(
        :assignment,
        due_date: 3.days.from_now,
        assignable: activity
      )

      allow(classwork_filter).to receive(:assignments).and_return(
        Assignment.where(id: [assignment_1.id, assignment_2.id, assignment_5.id])
      )

      classwork_filter.create_workset

      expect(classwork).to have_received(:new_workset).with(
        [
          assignment_2.assignable.id,
          assignment_1.assignable.id,
          assignment_5.assignable.id
        ]
      )
    end

    context 'when concept is nil,' do
      let(:activity) { create(:activity) }

      before do
        activity.concept.assessment = true
        activity.concept.save!
      end

      it 'creates a workset that includes assessments when lesson_id is ' \
         'specified' do
        assignment_5 = create(
          :assignment,
          assignable: activity,
          due_date: 3.days.ago,
          section: section
        )

        classwork_filter = described_class.new(
          assignment_day: 'overdue',
          classwork: classwork,
          lesson_id: activity.lesson_id
        )

        classwork_filter.create_workset

        expect(classwork).to have_received(:new_workset).with(
          [activity.id]
        )
      end

      it 'creates a workset that does not include assessments' do
        assignment_5 = create(
          :assignment,
          due_date: 3.days.from_now,
          assignable: activity
        )
        classwork_filter_2 = described_class.new(
          assignment_day: assignment_day,
          category: category,
          classwork: classwork
        )
        allow(classwork_filter_2).to receive(:assignments).and_return(
          Assignment.by_type(Activity).where(
            id: [assignment_1.id, assignment_2.id, assignment_5.id]
          )
        )

        classwork_filter_2.create_workset

        expect(classwork).to have_received(:new_workset).with(
          [assignment_2.assignable.id, assignment_1.assignable.id]
        )
      end
    end
  end

  describe '#first_activity_for_student_and_section' do
    let(:student) { build_stubbed(:student) }
    let(:activity_1) { build_stubbed(:activity) }
    let(:activity_2) { build_stubbed(:activity) }
    let(:attempt_1) { build_stubbed(:attempt, activity: activity_1) }
    let(:attempt_2) { build_stubbed(:attempt, activity: activity_2) }

    before do
      allow(Attempt).to receive(:find_by_student_section_and_activity)
        .and_return(attempt_1, attempt_2)
    end

    context 'when initialized for all assignments,' do
      let(:classwork_filter) do
        classwork_filter = described_class.new(
          assignment_day: assignment_day,
          category: category,
          classwork: classwork,
          concept: concept,
          include_all_assignments: true
        )
      end

      before do
        allow(classwork_filter).to receive(:activities)
          .and_return([activity_1, activity_2])
      end

      context 'when student has completed some activities,' do
        context 'when there is an activity that was started but not completed,' do
          it 'returns that activity' do
            allow(attempt_1).to receive(:complete?).and_return(false)
            expect(
              classwork_filter.first_activity_for_student(student)
            ).to eq(activity_1)
          end
        end

        context 'when there all only completed and non attempted activities,' do
          it 'returns the first non attempted activity' do
            allow(attempt_1).to receive(:complete?).and_return(true)
            expect(
              classwork_filter.first_activity_for_student(student)
            ).to eq(activity_2)
          end
        end

        context 'when all activities have been completed,' do
          it 'returns the first activity' do
            allow(attempt_1).to receive(:complete?).and_return(true)
            allow(attempt_2).to receive(:complete?).and_return(true)
            expect(
              classwork_filter.first_activity_for_student(student)
            ).to eq(activity_1)
          end
        end
      end
    end

    context 'when is not given a specific filter option,' do
      it 'returns the first activity' do
        allow(attempt_1).to receive(:complete?).and_return(true)
        classwork_filter = described_class.new(
          assignment_day: assignment_day,
          category: category,
          classwork: classwork,
          concept: concept
        )
        allow(classwork_filter).to receive(:activities)
          .and_return([activity_1, activity_2])

        expect(
          classwork_filter.first_activity_for_student(student)
        ).to eq(activity_1)
      end
    end

    context 'when no assignment day is given,' do
      it 'returns the first activity' do
        classwork_filter = described_class.new(
          category: category,
          classwork: classwork,
          concept: concept
        )
        allow(classwork_filter).to receive(:activities)
          .and_return([activity_1, activity_2])

        expect(
          classwork_filter.first_activity_for_student(student)
        ).to eq(activity_1)
      end
    end
  end

  describe '#has_assignments?' do
    let(:classwork_filter) do
      described_class.new(
        assignment_day: assignment_day,
        category: category,
        classwork: classwork,
        concept: concept
      )
    end
    let(:assignment) { build_stubbed(:assignment) }

    it 'returns true if assignments were found' do
      allow(classwork_filter).to receive(:assignments).and_return([assignment])

      expect(classwork_filter.has_assignments?).to eq(true)
    end

    it 'returns false if no assignments were found' do
      allow(classwork_filter).to receive(:assignments).and_return([])

      expect(classwork_filter.has_assignments?).to eq(false)
    end
  end

  describe '#incomplete_assignments_for_date' do
    before do
      @classwork_filter = described_class.new(classwork: classwork)
    end

    context 'when assignments have been completed,' do
      it 'does not return those assignments' do
        activity_1 = create(:activity)
        activity_2 = create(:activity)
        assignment_1 = create(
          :assignment,
          assignable: activity_1,
          due_date: Date.tomorrow,
          section: section
        )
        assignment_2 = create(
          :assignment,
          assignable: activity_2,
          due_date: Date.tomorrow,
          section: section
        )
        create(:attempt_completed, user: student, activity: activity_1, section: section)
        create(:attempt, user: student, activity: activity_2, section: section)
        assignments = @classwork_filter.incomplete_assignments_for_date(Date.tomorrow)

        expect(assignments).to eq([assignment_2])
      end
    end

    context 'when some activities are assigned individually,' do
      it 'includes only the activities assigned to all students or the ' \
         'current student' do
        # assigned to all students
        assignment_1 = create(
          :assignment,
          due_date: Date.tomorrow,
          individually_assignable: false,
          section: section
        )

        # individually assigned to current student
        assignment_2 = create(
          :assignment,
          due_date: Date.tomorrow,
          individually_assignable: true,
          section: section
        )

        IndividualAssignment.create!(
          activity_id: assignment_2.assignable_id,
          section_id: section.id,
          user_id: student.id
        )

        # individually assigned, but not to current student
        create(
          :assignment,
          due_date: Date.tomorrow,
          individually_assignable: true,
          section: section
        )

        assignments = @classwork_filter.incomplete_assignments_for_date(Date.tomorrow)
        expect(assignments).to contain_exactly(assignment_1, assignment_2)
      end
    end

    context 'when some activities are assigned with individual due dates,' do
      let(:due_date) { 2.days.from_now.to_date }
      let(:other_due_date) { due_date + 1 }

      it 'includes only the activities assigned to all students or the ' \
         'current student with no individual due date, or the current ' \
         'student with an individual due date matching the specified date' do
        # assigned to all students
        all_students_assignment = create(
          :assignment,
          due_date: due_date,
          individually_assignable: false,
          section: section
        )

        # individually assigned to current student, no individual due date
        individual_assignment_no_due_date = create(
          :assignment,
          due_date: due_date,
          individually_assignable: true,
          section: section
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_no_due_date.assignable_id,
          section_id: section.id,
          user_id: student.id
        )

        # individually assigned to current student, individual due date
        # matching specified date
        individual_assignment_matching_due_date = create(
          :assignment,
          due_date: other_due_date,
          individually_assignable: true,
          section_id: section.id
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_matching_due_date.assignable_id,
          due_date: due_date,
          section_id: section.id,
          user_id: student.id
        )

        # individually assigned to current student, individual due date
        # different from specified date
        individual_assignment_non_matching_due_date = create(
          :assignment,
          due_date: due_date,
          individually_assignable: true,
          section_id: section.id
        )

        IndividualAssignment.create!(
          activity_id: individual_assignment_non_matching_due_date.assignable_id,
          due_date: other_due_date,
          section_id: section.id,
          user_id: student.id
        )

        # individually assigned, but not to current student
        other_student_assignment = create(
          :assignment,
          due_date: other_due_date,
          individually_assignable: true,
          section_id: section.id
        )

        IndividualAssignment.create!(
          activity_id: other_student_assignment.assignable_id,
          due_date: due_date,
          section_id: section.id,
          user_id: create(:student).id
        )

        assignments = @classwork_filter.incomplete_assignments_for_date(due_date)
        expect(assignments).to contain_exactly(
          all_students_assignment,
          individual_assignment_no_due_date,
          individual_assignment_matching_due_date
        )
      end
    end

    context 'when a concept id is specified,' do
      it 'only returns assignments when activities belong to that concept' do
        concept_1 = create(:concept)
        concept_2 = create(:concept)
        activity_1 = create(:activity, concept: concept_1)
        activity_2 = create(:activity, concept: concept_2)
        assignment_1 = create(
          :assignment,
          assignable: activity_1,
          due_date: Date.tomorrow,
          section: section
        )
        assignment_2 = create(
          :assignment,
          assignable: activity_2,
          due_date: Date.tomorrow,
          section: section
        )
        assignments = @classwork_filter.incomplete_assignments_for_date(
          Date.tomorrow, concept_1
        )

        expect(assignments).to eq([assignment_1])
      end
    end

    context 'when a category is specified,' do
      it 'returns only assignments within that category' do
        category_1 = create(:category)
        category_2 = create(:category)
        assignment_1 = create(
          :assignment,
          category: category_1,
          due_date: Date.tomorrow,
          section: section
        )
        assignment_2 = create(
          :assignment,
          category: category_2,
          due_date: Date.tomorrow,
          section: section
        )
        assignments = @classwork_filter.incomplete_assignments_for_date(
          Date.tomorrow, nil, category_1
        )

        expect(assignments).to eq([assignment_1])
      end
    end

    context 'when there are assignment sets with custom ranks' do
      let(:due_date) { section.course.start_date + 7.days }

      let(:activity_1) { create(:activity) }
      let(:activity_2) { create(:activity) }
      let(:activity_3) { create(:activity) }

      let(:assignment_set_1) do
        create(
          :assignment_set,
          due_date: due_date,
          section: section
        )
      end

      let(:assignment_set_2) do
        create(
          :assignment_set,
          due_date: due_date + 1,
          section: section
        )
      end

      let!(:assignment_1) do
        create(
          :assignment,
          assignable: activity_1,
          due_date: due_date,
          rank: 1,
          section: section
        )
      end

      let!(:assignment_2) do
        create(
          :assignment,
          assignable: activity_2,
          due_date: due_date,
          rank: 2,
          section: section
        )
      end

      before do
        create(
          :assignment_set_activity,
          activity: activity_2,
          assignment_set: assignment_set_1,
          assignment_set_rank: 1
        )

        create(
          :assignment_set_activity,
          activity: activity_1,
          assignment_set: assignment_set_1,
          assignment_set_rank: 2
        )

        # should not get included in the results
        create(
          :assignment_set_activity,
          activity: activity_3,
          assignment_set: assignment_set_2,
          assignment_set_rank: 3
        )
      end

      it 'returns the assignments sorted by the custom rank instead of ' \
        'the rank from the assignment record' do
        expect(
          @classwork_filter.incomplete_assignments_for_date(due_date)
        ).to eq([assignment_2, assignment_1])
      end

      it 'sets the rank attribute of the assigned records to the custom ' \
        'rank instead of the rank from the assignment record' do
        expect(
          @classwork_filter.incomplete_assignments_for_date(due_date).map(&:rank)
        ).to eq([1, 2])
      end
    end
  end
end

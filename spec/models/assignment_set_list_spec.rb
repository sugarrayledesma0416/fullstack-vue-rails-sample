describe AssignmentSetList do
  include Rails.application.routes.url_helpers
  include AssignmentSetListHelpers

  let(:program) { create(:program) }
  let(:instructor) { create(:instructor) }

  shared_context 'with toc data' do
    let(:course) do
      create(:course, owner: instructor, program: program)
    end

    let(:section) do
      create(:section, course: course, instructor: instructor)
    end

    let(:unit) { create(:unit, program: program) }

    let(:lesson) do
      create(
        :lesson,
        name: 'Lesson 1 long',
        label: 'Lesson 1<br >short <b>title</b>',
        toc_entries: [strand]
      )
    end

    # manually setting the id here to avoid intermittent duplicate id
    # errors with concept_2
    let(:concept_1) do
      create(
        :concept,
        id: strand.location.to_i + 1,
        background_color: '#FFF',
        lesson: lesson,
        rank: 0,
        name: 'Strand<br>1 <b>title</b>'
      )
    end

    let(:concept_2) do
      create(
        :concept,
        id: strand.location,
        background_color: '#000',
        lesson: lesson,
        rank: 1,
        name: 'Strand<br />2 <b>title</b>'
      )
    end

    let(:assessments_concept) do
      create(
        :concept,
        id: strand.location.to_i + 2,
        background_color: '#606060',
        lesson: lesson,
        rank: 17,
        name: 'Strand<br />Quiz <b>title</b>'
      )
    end

    let(:activity_1) do
      create(
        :activity,
        concept: concept_1,
        lesson: lesson,
        title: 'Activity<br>1 <b>title</b>'
      )
    end

    let(:activity_2) do
      create(
        :activity,
        concept: concept_1,
        lesson: lesson,
        title: 'Activity<br />2 <b>title</b>'
      )
    end

    let(:activity_3) do
      create(
        :activity,
        concept: concept_2,
        lesson: lesson,
        title: 'Activity<br/>3 <b>title</b>'
      )
    end

    let(:due_date_1) { course.start_date + 7.days }
    let(:due_date_2) { course.start_date + 9.days }

    let(:strand) { create(:toc_entry) }
  end

  shared_context 'with custom ordered activities' do
    let(:set) do
      create(
        :assignment_set,
        due_date: due_date_1,
        section: section
      ) do |set|
        create(
          :assignment_set_activity,
          assignment_set: set,
          activity: activity_2,
          assignment_set_rank: 200
        )
        create(
          :assignment_set_activity,
          assignment_set: set,
          activity: activity_3,
          assignment_set_rank: 100 # Lowest rank, this activity should be first.
        )
      end
    end
  end

  describe '#entries' do
    include_context 'with toc data'
    let(:list) { described_class.new(section) }

    context 'with a due date with custom ordered assignments' do
      include_context 'with custom ordered activities'

      before do
        create(
          :assignment,
          assignable: activity_2,
          due_date: due_date_1,
          rank: 2,
          section: section
        )

        create(
          :assignment,
          assignable: activity_3,
          due_date: due_date_1,
          rank: 2,
          section: section
        )
      end

      it('orders the assignments based on the assignment set data') do
        expected = make_custom_order_expected_entries
        expect(list.entries).to eq(expected)
      end

      it 'does not error when an activity has a nil toc_location_rank' do
        activity_2.update!(toc_location_rank: nil)

        expect { list.entries }.not_to raise_error
      end
    end

    it 'returns an assignment set for each due date for which the ' \
       'specified section has assignments' do
      # Create assignment with later due date first to demonstrate
      # due-date sorting.
      create(
        :assignment,
        assignable: activity_1,
        due_date: due_date_2,
        rank: 1,
        section: section
      )

      create(
        :assignment,
        assignable: activity_2,
        due_date: due_date_1,
        rank: 2,
        section: section
      )

      create(
        :assignment,
        assignable: activity_3,
        due_date: due_date_1,
        rank: 3,
        section: section
      )

      # Assignment in a different section won't get returned as part of
      # any assignment set.
      activity_4 = create(
        :activity,
        title: 'Activity 4',
        concept: concept_2,
        lesson: lesson
      )

      create(
        :assignment,
        assignable: activity_4,
        due_date: due_date_1,
        section: create(:section, course: course, instructor: instructor)
      )
      expected = make_no_custom_order_assignment_set_expected_entries
      expect(list.entries).to eq(expected)
    end

    context 'with default ordered activities containing igc and assessments' do
      let(:instructor_activity_1) do
        create(
          :instructor_created_activity,
          concept: concept_2,
          lesson: lesson,
          title: 'IGC<br/>1 <b>title</b>',
          toc_entry_id: strand.location
        )
      end

      let(:instructor_activity_2) do
        create(
          :instructor_created_activity,
          concept: concept_2,
          lesson: lesson,
          title: 'IGC<br/>2 <b>title</b>',
          toc_entry_id: strand.location
        )
      end

      let(:assessment) do
        create(
          :activity,
          concept: assessments_concept,
          activity_type: 'exam',
          lesson: lesson,
          title: 'Assesment<br/>1 <b>title</b>'
        )
      end

      before do
        allow(Maestro::LicenseGroup).to receive(:all).and_return(
          [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
        )

        create(
          :assignment,
          assignable: assessment,
          due_date: due_date_1,
          rank: 2,
          section: section
        )

        create(
          :assignment,
          assignable: activity_3,
          due_date: due_date_1,
          rank: 2,
          section: section
        )

        create(
          :assignment,
          assignable: activity_1,
          due_date: due_date_1,
          rank: 2,
          section: section
        )

        create(
          :assignment,
          assignable: activity_2,
          due_date: due_date_1,
          rank: 2,
          section: section
        )

        create(
          :assignment,
          assignable: instructor_activity_1,
          due_date: due_date_1,
          rank: 1,
          section: section
        )

        create(
          :assignment,
          assignable: instructor_activity_2,
          due_date: due_date_1,
          rank: 1,
          section: section
        )
      end

      it 'returns instructor generated activities at the top of the stand ' \
         'and assessments at the bottom of the lesson' \
         'in the strands order ' do
        expected_entries = make_igc_assignment_set_entries
        expect(list.entries[:default_order]).to eq(expected_entries)
      end

      it 'does not error when an activity has a nil toc_location_rank' do
        activity_1.update!(toc_location_rank: nil)

        expect { list.entries[:default_order] }.not_to raise_error
      end
    end

    context 'with custom ordered activities containing igc and assessments' do
      let(:assignment_set) do
        create(:assignment_set, due_date: due_date_1, section: section)
      end

      let(:activity_1) do
        create(
          :activity,
          concept: concept_2,
          toc_location_rank: 1,
          toc_location: 1,
          activity_type: 'composition',
          lesson: lesson,
          title: 'Activity 1 title'
        )
      end
      let(:assessment_1) do
        create(
          :activity,
          concept: assessments_concept,
          toc_location_rank: 1,
          toc_location: 1,
          activity_type: 'exam',
          lesson: lesson,
          title: 'Assessment 1 title'
        )
      end
      let(:instructor_activity_1) do
        create(
          :instructor_created_activity,
          concept: concept_2,
          lesson: lesson,
          title: 'IGC<br/>1 <b>title</b>',
          toc_entry_id: strand.location
        )
      end
      let(:instructor_activity_2) do
        create(
          :instructor_created_activity,
          concept: concept_2,
          lesson: lesson,
          title: 'IGC<br/>2 <b>title</b>',
          toc_entry_id: strand.location
        )
      end

      before do
        allow(Maestro::LicenseGroup).to receive(:all).and_return(
          [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
        )

        create(
          :assignment,
          assignable: activity_1,
          due_date: due_date_1,
          rank: 2,
          section: section
        )

        create(
          :assignment,
          assignable: assessment_1,
          due_date: due_date_1,
          rank: 2,
          section: section
        )

        create(
          :assignment,
          assignable: instructor_activity_1,
          due_date: due_date_1,
          rank: 1,
          section: section
        )

        create(
          :assignment,
          assignable: instructor_activity_2,
          due_date: due_date_1,
          rank: 1,
          section: section
        )

        create(
          :assignment_set_activity,
          activity: activity_1,
          assignment_set: assignment_set,
          assignment_set_rank: 4
        )

        create(
          :assignment_set_activity,
          activity: instructor_activity_1,
          assignment_set: assignment_set,
          assignment_set_rank: 3
        )

        create(
          :assignment_set_activity,
          activity: instructor_activity_2,
          assignment_set: assignment_set,
          assignment_set_rank: 2
        )

        create(
          :assignment_set_activity,
          activity: assessment_1,
          assignment_set: assignment_set,
          assignment_set_rank: 1
        )
      end

      it 'returns assignment sets with the activities sorted by the assignment_set_rank' do
        expected_entries = make_igc_assessment_set_custom_entries
        expect(list.entries).to eq(expected_entries)
      end

      it 'does not error when an activity has a nil toc_location_rank' do
        activity_1.update!(toc_location_rank: nil)

        expect { list.entries }.not_to raise_error
      end
    end
  end

  describe described_class::CsvData do
    describe '#to_csv' do
      include_context 'with toc data'
      let(:list) { AssignmentSetList.new(section) }
      let(:csv_data) do
        described_class.new(
          list.unordered_assignment_scope.order(described_class.module_parent::ASSIGNMENT_ORDER)
        )
      end

      before do
        create(
          :assignment,
          assignable: activity_1,
          due_date: due_date_2,
          section: section,
          rank: 33
        )

        create(
          :assignment,
          assignable: activity_2,
          due_date: due_date_1,
          section: section,
          rank: 44
        )

        create(
          :assignment,
          assignable: activity_3,
          due_date: due_date_1,
          section: section,
          rank: 55
        )

        assignment_set = create(
          :assignment_set,
          due_date: due_date_1,
          section: section
        )

        create(
          :assignment_set_activity,
          activity: activity_2,
          assignment_set: assignment_set,
          assignment_set_rank: 22
        )

        create(
          :assignment_set_activity,
          activity: activity_3,
          assignment_set: assignment_set,
          assignment_set_rank: 11
        )
      end

      it 'returns rows for all due dates when the course start and ' \
         'end date are specified' do
        expect(
          csv_data.rows(
            start_date: course.start_date,
            end_date: course.end_date
          )
        ).to eq(
          [
            described_class::HEADER_ROW,
            [
              due_date_1.strftime('%-m/%d'),
              'Yes',
              11,
              'Lesson 1 short title',
              'Strand 2 title',
              'Activity 3 title'
            ],
            [
              due_date_1.strftime('%-m/%d'),
              'Yes',
              22,
              'Lesson 1 short title',
              'Strand 1 title',
              'Activity 2 title'
            ],
            [
              due_date_2.strftime('%-m/%d'),
              'No',
              33,
              'Lesson 1 short title',
              'Strand 1 title',
              'Activity 1 title'
            ]
          ]
        )
      end

      it 'returns only rows between the specified start and end date' do
        expect(
          csv_data.rows(
            start_date: due_date_1,
            end_date: due_date_1
          )
        ).to eq(
          [
            described_class::HEADER_ROW,
            [
              due_date_1.strftime('%-m/%d'),
              'Yes',
              11,
              'Lesson 1 short title',
              'Strand 2 title',
              'Activity 3 title'
            ],
            [
              due_date_1.strftime('%-m/%d'),
              'Yes',
              22,
              'Lesson 1 short title',
              'Strand 1 title',
              'Activity 2 title'
            ]
          ]
        )
      end
    end
  end
end

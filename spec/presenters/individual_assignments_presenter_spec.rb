describe IndividualAssignmentsPresenter do
  let(:course) do
    create(
      :course,
      allow_past_end_date: true,
      end_date: '2021-10-05',
      start_date: '2021-09-25'
    )
  end

  let(:program) { create(:program) }
  let(:section) { create(:section, course: course) }

  shared_context 'with toc and assignment data' do
    let(:student) { create(:student) }
    let(:lesson_1_strand) { create(:toc_entry, title: '<b>b &amp; c</b>') }
    let(:lesson_2_strand) { create(:toc_entry) }
    let(:unit) { create(:unit, program: program) }

    let(:lesson_1) do
      create(:lesson, toc_entries: [lesson_1_strand], unit: unit)
    end

    let(:lesson_2) do
      create(:lesson, toc_entries: [lesson_2_strand], unit: unit)
    end

    let(:lesson_1_concept) do
      create(
        :concept,
        id: lesson_1_strand.location,
        lesson: lesson_1,
        name: lesson_1_strand.title,
        program: program
      )
    end

    let(:lesson_2_concept) do
      create(
        :concept,
        id: lesson_2_strand.location,
        lesson: lesson_2,
        name: lesson_2_strand.title,
        program: program
      )
    end

    let(:activity_1) do
      create(
        :activity,
        concept: lesson_1_concept,
        lesson: lesson_1,
        title: '<b>a &amp; b</b>',
        toc_location: lesson_1_strand.location
      )
    end

    let(:activity_2) do
      create(
        :activity,
        concept: lesson_2_concept,
        lesson: lesson_2,
        toc_location: lesson_2_strand.location
      )
    end

    before do
      create(:active_enrollment, section: section, user: student)

      create(
        :assignment,
        assignable: activity_1,
        due_date: '2021-09-25',
        section: section
      )

      create(
        :assignment,
        assignable: activity_2,
        due_date: '2021-10-02',
        section: section
      )
    end
  end

  describe '#entries' do
    include_context 'with toc and assignment data'

    it 'updates due_date attributes to a month-day format' do
      presenter = described_class.new(section.id, {})

      expect(presenter.entries["user_#{student.id}"].map(&:due_date)).to eq(
        ['9/25/2021', '10/2/2021']
      )
    end

    it 'sanitizes html tags and entities from strand names' do
      presenter = described_class.new(section.id, {})

      expect(presenter.entries["user_#{student.id}"].first.strand_name).to eq('b & c')
    end

    it 'sanitizes html tags and entities from activity titles' do
      presenter = described_class.new(section.id, {})

      expect(presenter.entries["user_#{student.id}"].first.activity_title).to eq('a & b')
    end

    it 'returns assignments from all lessons when neither a lesson_id or ' \
       'week param is set' do
      presenter = described_class.new(section.id, {})

      expect(presenter.entries["user_#{student.id}"].map(&:assignable_id)).to eq(
        [activity_1.id, activity_2.id]
      )
    end

    it 'returns only assignments for a lesson if a lesson_id param is set' do
      presenter = described_class.new(section.id, lesson_id: lesson_1.id)

      expect(presenter.entries["user_#{student.id}"].map(&:assignable_id)).to eq(
        [activity_1.id]
      )
    end

    it 'returns only assignments for a week if a week param is set' do
      presenter = described_class.new(section.id, week: '2021-09-26')

      expect(presenter.entries["user_#{student.id}"].map(&:assignable_id)).to eq(
        [activity_2.id]
      )
    end

    context 'when some assignments are individually-assignable' do
      before do
        activity_1.assignments.first.update!(individually_assignable: true)
      end

      it 'returns only individually-assignable assignments if exporting a ' \
         'csv and only_individual param is true' do
        presenter = described_class.new(
          section.id,
          format: 'csv',
          only_individual: 'true'
        )

        expect(presenter.entries["user_#{student.id}"].map(&:assignable_id)).to eq(
          [activity_1.id]
        )
      end

      it 'does not return only individually-assignable assignments if ' \
         'only_individual param is true but not exporting a csv' do
        presenter = described_class.new(section.id, only_individual: 'true')

        expect(presenter.entries["user_#{student.id}"].map(&:assignable_id)).to eq(
          [activity_1.id, activity_2.id]
        )
      end

      it 'does not return only individually-assignable assignments if ' \
         'exporting a csv but only_individual param is false' do
        presenter = described_class.new(
          section.id,
          format: 'csv',
          only_individual: 'false'
        )

        expect(presenter.entries["user_#{student.id}"].map(&:assignable_id)).to eq(
          [activity_1.id, activity_2.id]
        )
      end

      it 'does not return only individually-assignable assignments if ' \
         'exporting a csv but only_individual param is not set' do
        presenter = described_class.new(section.id, format: 'csv')

        expect(presenter.entries["user_#{student.id}"].map(&:assignable_id)).to eq(
          [activity_1.id, activity_2.id]
        )
      end
    end
  end

  describe '#to_csv' do
    include_context 'with toc and assignment data'

    let(:csv_data_class) { described_class::CsvData }
    let(:presenter) { described_class.new(section.id, {}) }
    let(:csv_data) { instance_double(csv_data_class, rows: []) }

    before do
      allow(csv_data_class).to receive(:new).and_return(csv_data)
    end

    it 'instantiates a CsvData instance, passing in current entries' do
      presenter.to_csv

      expect(csv_data_class).to have_received(:new).with(presenter.entries)
    end

    it 'creates a windows-1252-encoded CSV from the rows of the CsvData instance' do
      allow(csv_data).to receive(:rows).and_return([['é'], ['ü']])

      csv = presenter.to_csv

      result = CSV.parse(csv)
      expect(result).to eq(
        [['é'.encode('windows-1252')], ['ü'.encode('windows-1252')]]
      )
    end
  end

  describe '#lesson_options' do
    let(:unit_1) { create(:unit, name: 'Unit 1', program: program, rank: 1) }
    let(:unit_2) { create(:unit, name: 'Unit 2', program: program, rank: 2) }

    let!(:lesson_1) do
      create(:lesson, label: 'Lesson 1', name: 'Lesson 1 Long', unit: unit_1)
    end

    let!(:lesson_2) do
      create(:lesson, label: '<b>Lesson &amp; 2</b>', name: 'Lesson 2 Long', unit: unit_2)
    end

    it 'returns an array of lessons in the current program' do
      presenter = described_class.new(section.id, program_id: program.id)

      expect(presenter.lesson_options).to eq(
        [
          { name: 'All Lessons', selected: true, value: '' },
          { name: 'Lesson 1', selected: false, value: lesson_1.id },
          { name: 'Lesson & 2', selected: false, value: lesson_2.id }
        ]
      )
    end

    it 'marks the lesson matching a non-blank lesson_id param as selected' do
      presenter = described_class.new(
        section.id,
        lesson_id: lesson_1.id.to_s,
        program_id: program.id
      )

      expect(presenter.lesson_options).to eq(
        [
          { name: 'All Lessons', selected: false, value: '' },
          { name: 'Lesson 1', selected: true, value: lesson_1.id },
          { name: 'Lesson & 2', selected: false, value: lesson_2.id }
        ]
      )
    end
  end

  describe '#week_options' do
    it 'returns an array of weeks based on the course range' do
      presenter = described_class.new(section.id, {})

      expect(presenter.week_options).to eq(
        [
          { name: 'All Weeks', selected: true, value: '' },
          { name: 'Week 1: 9/19/21 - 9/25/21', selected: false, value: '2021-09-19' },
          { name: 'Week 2: 9/26/21 - 10/2/21', selected: false, value: '2021-09-26' },
          { name: 'Week 3: 10/3/21 - 10/9/21', selected: false, value: '2021-10-03' }
        ]
      )
    end

    it 'marks the week matching a non-blank week param as selected' do
      presenter = described_class.new(section.id, week: '2021-09-26')

      expect(presenter.week_options).to eq(
        [
          { name: 'All Weeks', selected: false, value: '' },
          { name: 'Week 1: 9/19/21 - 9/25/21', selected: false, value: '2021-09-19' },
          { name: 'Week 2: 9/26/21 - 10/2/21', selected: true, value: '2021-09-26' },
          { name: 'Week 3: 10/3/21 - 10/9/21', selected: false, value: '2021-10-03' }
        ]
      )
    end
  end

  describe described_class::CsvData do
    describe '#rows' do
      include_context 'with toc and assignment data'

      before do
        activity_1.assignments.first.update!(
          individually_assignable: true
        )
      end

      let(:presenter) { IndividualAssignmentsPresenter.new(section.id, {}) }
      let(:csv_data) { described_class.new(presenter.entries) }

      it 'returns an array of strand names as the first row' do
        expect(csv_data.rows.first).to eq(
          ['', '', 'b & c', lesson_2_strand.title]
        )
      end

      it 'returns an array of activity titles as the second row' do
        expect(csv_data.rows[1]).to eq(
          ['', '', 'a & b', activity_2.title]
        )
      end

      it 'returns the individually-assignable status as the third row' do
        expect(csv_data.rows[2]).to eq(
          ['', 'Individually Assignable', 'yes', 'no']
        )
      end

      it 'returns the due dates with column labels for the student ' \
         'name columns as the fourth row' do
        expect(csv_data.rows[3]).to eq(
          ['Last name', 'First name', '9/25/2021', '10/2/2021']
        )
      end

      it 'returns student name and individually-assigned status for each ' \
         'student starting in the fifth row' do
        expect(csv_data.rows[4]).to eq(
          [student.last_name, student.first_name, '', 'x']
        )
      end
    end
  end
end

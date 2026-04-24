describe Gradebook::Standards::StudentDetailReportPresenter, new_gb_sync: true do
  let(:program) { create(:program_with_assessment_toc_entries) }
  let(:concepts) { program.lessons.map { |lesson| create(:concept_for_test, lesson:, program:) } }
  let(:course) { create(:course, program:) }
  let(:section) { create(:section, course:) }
  let(:standard_set) { create(:standard_set) }
  let(:student) { create(:user) }

  let(:presenter_kwargs) do
    { section_id: section.id,
      standard_set_id: standard_set.id,
      student_id: student.id }
  end

  let(:presenter) do
    described_class.new(**presenter_kwargs)
  end

  let(:points_earned) do
    { unit_1: { 'Mid-Unit': 60, 'End-of-Unit': 70 },
      unit_2: { 'Mid-Unit': 70, 'End-of-Unit': 80, 'Mid-Book': 85 },
      unit_3: { 'Mid-Unit': 80, 'End-of-Unit': 90 } }
  end

  let(:mid_unit_scores) { [60.0, 70.0, 80.0] }
  let(:end_unit_scores) { [70.0, 80.0, 90.0] }
  let(:mid_book_score) { 85.0 }
  # TODO: Remove this, or change it to nil, once the fix that ignores unsubmitted assessments is
  # merged.
  let(:end_book_score) { 0.0 }

  let(:assessments) do
    {
      unit_1: {
        'Mid-Unit': create(:activity,
                           concept: concepts[0],
                           title: 'Unit 1 Mid-Unit Assessment',
                           lesson: concepts[0].lesson),
        'End-of-Unit': create(:activity,
                              concept: concepts[0],
                              title: 'Unit 1 End-of-Unit Assessment',
                              lesson: concepts[0].lesson)
      },
      unit_2: {
        'Mid-Unit': create(:activity,
                           concept: concepts[2],
                           title: 'Unit 2 Mid-Unit Assessment',
                           lesson: concepts[2].lesson),
        'End-of-Unit': create(:activity,
                              concept: concepts[2],
                              title: 'Unit 2 End-of-Unit Assessment',
                              lesson: concepts[2].lesson),
        'Mid-Book': create(:activity,
                           concept: concepts[2],
                           title: 'Unit 2 Mid-Book Assessment',
                           lesson: concepts[2].lesson)
      },
      unit_3: {
        'Mid-Unit': create(:activity,
                           concept: concepts[4],
                           title: 'Unit 3 Mid-Unit Assessment',
                           lesson: concepts[4].lesson),
        'End-of-Unit': create(:activity,
                              concept: concepts[4],
                              title: 'Unit 3 End-of-Unit Assessment',
                              lesson: concepts[4].lesson),
        'End-of-Book': create(:activity,
                              concept: concepts[4],
                              title: 'Unit 3 End-of-Book Assessment',
                              lesson: concepts[4].lesson)
      }
    }
  end

  describe 'initialization' do
    it 'throws an error if section_id is not given' do
      expect do
        described_class.new(**presenter_kwargs.slice(:standard_set_id, :student_id))
      end.to raise_error(ArgumentError, 'missing keyword: :section_id')
    end

    it 'throws an error if standard_set_id is not given' do
      expect do
        described_class.new(**presenter_kwargs.slice(:section_id, :student_id))
      end.to raise_error(ArgumentError, 'missing keyword: :standard_set_id')
    end

    it 'throws an error if student_id is not given' do
      expect do
        described_class.new(**presenter_kwargs.slice(:section_id, :standard_set_id))
      end.to raise_error(ArgumentError, 'missing keyword: :student_id')
    end
  end

  describe '#chart_data' do
    before do
      allow_any_instance_of(Activity).to receive(:proficiency_assessment?).and_return(true)

      %i[unit_1 unit_2 unit_3].each do |unit_key|
        %i[Mid-Unit End-of-Unit Mid-Book End-of-Book].each do |series_key|
          next unless assessments[unit_key][series_key]

          create(:assignment,
                 assignable: assessments[unit_key][series_key],
                 due_date: Time.zone.today - 2.days,
                 section:)

          GradebookEngine::GradebookAPI.submit(
            student.id,
            section.id,
            assessments[unit_key][series_key].id,
            section.school_id,
            points_earned: points_earned[unit_key][series_key],
            points_possible: 100,
            submitted_at: Time.zone.now
          )
        end
      end
    end

    it 'includes unit data in ascending order by unit rank' do
      expect(presenter.chart_data[:units]).to eq(
        program.units.sort_by(&:rank).map do |unit|
          { id: unit.id,
            rank: unit.rank,
            name: unit.name,
            label: unit.label }
        end
      )
    end

    it 'includes assessment data by unit' do
      expect(presenter.chart_data[:assessments_by_unit]).to eq(
        { program.units[0].id => { 'Mid-Unit' => mid_unit_scores[0],
                                   'End-of-Unit' => end_unit_scores[0],
                                   'Mid-Book' => nil,
                                   'End-of-Book' => nil },
          program.units[1].id => { 'Mid-Unit' => mid_unit_scores[1],
                                   'End-of-Unit' => end_unit_scores[1],
                                   'Mid-Book' => mid_book_score,
                                   'End-of-Book' => nil },
          program.units[2].id => { 'Mid-Unit' => mid_unit_scores[2],
                                   'End-of-Unit' => end_unit_scores[2],
                                   'Mid-Book' => nil,
                                   'End-of-Book' => end_book_score } }
      )
    end

    it 'includes assessment data by series' do
      expect(presenter.chart_data[:assessments_by_series]).to eq(
        {
          'Mid-Unit' => mid_unit_scores,
          'End-of-Unit' => end_unit_scores,
          'Mid-Book' => [nil, mid_book_score, nil],
          'End-of-Book' => [nil, nil, end_book_score]
        }
      )
    end

    context 'when assessments are not standards tests' do
      before do
        allow_any_instance_of(Activity).to receive(:proficiency_assessment?).and_return(false)
      end

      it 'omits them from assessments by unit' do
        expect(presenter.chart_data[:assessments_by_unit]).to eq(
          { program.units[0].id => { 'Mid-Unit' => nil,
                                     'End-of-Unit' => nil,
                                     'Mid-Book' => nil,
                                     'End-of-Book' => nil },
            program.units[1].id => { 'Mid-Unit' => nil,
                                     'End-of-Unit' => nil,
                                     'Mid-Book' => nil,
                                     'End-of-Book' => nil },
            program.units[2].id => { 'Mid-Unit' => nil,
                                     'End-of-Unit' => nil,
                                     'Mid-Book' => nil,
                                     'End-of-Book' => nil } }
        )
      end

      it 'omits them from assessments by series' do
        expect(presenter.chart_data[:assessments_by_series]).to eq(
          {
            'Mid-Unit' => [nil, nil, nil],
            'End-of-Unit' => [nil, nil, nil],
            'Mid-Book' => [nil, nil, nil],
            'End-of-Book' => [nil, nil, nil]
          }
        )
      end
    end

    context 'when assessments are not proficiency assessments' do
      before do
        allow_any_instance_of(Activity).to receive(:proficiency_assessment?).and_return(false)
      end

      it 'omits them from assessments by unit' do
        expect(presenter.chart_data[:assessments_by_unit]).to eq(
                                                                { program.units[0].id => { 'Mid-Unit' => nil,
                                                                                           'End-of-Unit' => nil,
                                                                                           'Mid-Book' => nil,
                                                                                           'End-of-Book' => nil },
                                                                  program.units[1].id => { 'Mid-Unit' => nil,
                                                                                           'End-of-Unit' => nil,
                                                                                           'Mid-Book' => nil,
                                                                                           'End-of-Book' => nil },
                                                                  program.units[2].id => { 'Mid-Unit' => nil,
                                                                                           'End-of-Unit' => nil,
                                                                                           'Mid-Book' => nil,
                                                                                           'End-of-Book' => nil } }
                                                              )
      end

      it 'omits them from assessments by series' do
        expect(presenter.chart_data[:assessments_by_series]).to eq(
                                                                  {
                                                                    'Mid-Unit' => [nil, nil, nil],
                                                                    'End-of-Unit' => [nil, nil, nil],
                                                                    'Mid-Book' => [nil, nil, nil],
                                                                    'End-of-Book' => [nil, nil, nil]
                                                                  }
                                                                )
      end
    end

    context 'when an attempt for an assessment is reset' do
      it 'omits the assessment from assessments by unit' do
        GradebookEngine::GradebookAPI.reset_work(
          student.id,
          section.id,
          assessments[:unit_2][:'Mid-Unit'].id,
          section.school_id
        )
        expect(
          presenter.chart_data[:assessments_by_unit][program.units[1].id]['Mid-Unit']
        ).to be_nil
      end
    end

    describe 'mid/end-of-book unit names' do
      it 'finds the correct Mid-Book unit name' do
        expect(
          presenter.chart_data[:mid_book_unit_name]
        ).to eq(
          program.units[1].name.split(' | ').first
        )
      end

      it 'finds the correct End-of-Book unit' do
        expect(
          presenter.chart_data[:end_book_unit_name]
        ).to eq(
          program.units[2].name.split(' | ').first
        )
      end
    end

    it 'excludes pending scores' do
      create(:gb_score_action,
             action: { points_earned: 70 },
             activity_id: assessments[:unit_2][:'Mid-Unit'].id,
             section_id: section.id,
             summation: { pending: true,
                          points_earned: points_earned[:unit_2][:'Mid-Unit'],
                          points_possible: 100 },
             user_id: student.id)
      expect(presenter.chart_data[:assessments_by_unit][program.units[1].id]).to eq(
        { 'Mid-Unit' => nil,
          'End-of-Unit' => end_unit_scores[1],
          'Mid-Book' => mid_book_score,
          'End-of-Book' => nil }
      )
    end
  end

  describe '#cumulative_average' do
    before do
      # don't assign anything from unit 3
      allow_any_instance_of(Activity).to receive(:proficiency_assessment?).and_return(true)

      %i[unit_1 unit_2].each do |unit_key|
        %i[Mid-Unit End-of-Unit Mid-Book].each do |series_key|
          next unless assessments[unit_key][series_key]

          create(:assignment,
                 assignable: assessments[unit_key][series_key],
                 due_date: Time.zone.today - 2.days,
                 section:)

          GradebookEngine::GradebookAPI.submit(
            student.id,
            section.id,
            assessments[unit_key][series_key].id,
            section.school_id,
            points_earned: points_earned[unit_key][series_key],
            points_possible: 100,
            submitted_at: Time.zone.now
          )
        end
      end
    end

    it 'returns total points earned divided by total points possible for submitted, graded assessments' do
      #unit_1: { 'Mid-Unit': 60, 'End-of-Unit': 70 },
      #unit_2: { 'Mid-Unit': 70, 'End-of-Unit': 80, 'Mid-Book': 85 },
      # expected average is 60 + 70 + 70 + 80 + 85 / 5 = 73
      expect(presenter.cumulative_average).to eq(73)
    end

    it 'does not include unassigned assessments' do
      # have student submit a unit 3 assessment
      # expect cumulative average not to include that assessment
      GradebookEngine::GradebookAPI.submit(
        student.id,
        section.id,
        assessments[:unit_3][:'Mid-Unit'].id,
        section.school_id,
        points_earned: points_earned[:unit_3][:'Mid-Unit'],
        points_possible: 100,
        submitted_at: Time.zone.now
      )

      expect(presenter.cumulative_average).to eq(73)
    end

    it 'includes score = 0 for submitted/graded assessments' do
      # assign a unit 3 assessment
      # have student submit that assessment with a score of 0
      create(:assignment,
             assignable: assessments[:unit_3][:'Mid-Unit'],
             due_date: Time.zone.today - 2.days,
             section:)

      GradebookEngine::GradebookAPI.submit(
        student.id,
        section.id,
        assessments[:unit_3][:'Mid-Unit'].id,
        section.school_id,
        points_earned: 0,
        points_possible: 100,
        submitted_at: Time.zone.now
      )
      # expect cumulative average to include that score
      # expected average is 60 + 70 + 70 + 80 + 85 + 0 / 600 = 0.6083333
      expect(presenter.cumulative_average).to be_within(0.001).of(60.833)
    end

    it 'does not include score = 0 for unsubmitted assessments' do
      # assign a unit 3 assessment
      # don't have student submit that assessment
      create(:assignment,
             assignable: assessments[:unit_3][:'Mid-Unit'],
             due_date: Time.zone.today - 2.days,
             section:)

      # expect cumulative average not to include a score of 0 for that assessment
      expect(presenter.cumulative_average).to eq(73)
    end

    it 'does not include pending-grading assessments' do
      # assign a unit 3 assessment
      # have student submit that assessment, with pending = true
      create(:assignment,
             assignable: assessments[:unit_3][:'Mid-Unit'],
             due_date: Time.zone.today - 2.days,
             section:)

      GradebookEngine::GradebookAPI.submit(
        student.id,
        section.id,
        assessments[:unit_3][:'Mid-Unit'].id,
        section.school_id,
        pending: true,
        points_earned: 0,
        points_possible: 100,
        submitted_at: Time.zone.now
      )
      # expect cumulative average not to include a score of 0 for that assessment
      expect(presenter.cumulative_average).to eq(73)
    end

    context 'when there are no submitted/graded assessments' do
      it 'returns nil' do
        # create second student
        student_2 = create(:user)
        presenter_2 = described_class.new(
          section_id: section.id,
          standard_set_id: standard_set.id,
          student_id: student_2.id
        )

        # expect cumulative average for second student to be nil
        expect(presenter_2.cumulative_average).to be_nil
      end
    end
  end
end

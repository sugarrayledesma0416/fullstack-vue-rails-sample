describe SharedActivityViewer do
  class TestPresenter
    include SharedActivityViewer

    def assignment
      section.assignments.by_activities(activity).first
    end
  end

  let(:student) { create(:student) }
  let(:course) { create(:course) }
  let(:section) { create(:section, course:) }
  let!(:enrollment) { create(:enrollment, section: section, user: student) }
  let(:student2) { create(:student) }
  let!(:enrollment2) { create(:enrollment, section: section, user: student2) }
  let(:student3) { create(:student) }
  let!(:enrollment3) { create(:enrollment, section: section, user: student3) }

  let(:assessment_activity) { create_assessment }
  let(:attempt_opened) { create_attempt(status_code: AttemptStatus::CODE_OPENED) }
  let(:score_submitted) { create_mock_score }
  let(:score_reset) do
    create_mock_score(submitted_at: nil,
                      pending: false,
                      action: {type: 'reset_work'})
  end
  let(:score_dropped) do
    create_mock_score(submitted_at: nil,
                      pending: false,
                      action: {type: 'drop_score'})
  end
  let(:presenter) { TestPresenter.new(assessment_activity, student, section) }

  def create_assignment(opts = {})
    default_params = {assignable: assessment_activity,
                      section: section,
                      due_date: 1.day.ago.to_date,
                      custom_due_time: '2000-01-01 20:00:00',
                      show_assessment: 'a specific date and time',
                      show_at: 5.days.ago,
                      grade_availability: 'on_grading'
                     }
    scoring_ruleset = create(:scoring_ruleset)
    category = create(:category, current_scoring_ruleset_id: scoring_ruleset.id)
    opts.merge(category: category)
    assignment = create(:assignment, default_params.merge(opts))
    assignment
  end

  def create_assessment(opts = {})
    activity = create(:activity, opts)
    allow(activity).to receive(:assessment?).and_return(true)
    allow(activity).to receive(:strand_singular_label).and_return('Tests')
    activity
  end

  def create_attempt(opts = {})
    default_params = {user: student,
                      activity: assessment_activity,
                      section: section,
                      status_code: AttemptStatus::CODE_OPENED
                     }
    create(:attempt, default_params.merge(opts))
  end

  def create_mock_score(opts = {})
    default_params = {submitted_at: 2.days.ago, pending?: false}
    score = instance_double(GradebookEngine::CurrentScoreAction, default_params.merge(opts))
    allow(GradebookEngine::GradebookAPI).to receive(:find_score).and_return(score)

    unless score.submitted_at.nil?
      allow(GradebookEngine::GradebookAPI).to receive(:find_submitted).and_return([score])
    end
    score
  end

  describe '#redirect_to_dashboard' do
    before do
      allow(student).to receive(:enrolled_in_section?).with(section).and_return(true)
    end

    context 'when the activity is first opened' do
      it 'returns false' do
        create_assignment(due_date: 1.day.from_now)
        expect(presenter.redirect_to_dashboard?).to be_falsey
      end

      it 'returns true if not assigned' do
        # assessments can't be viewed if they aren't assigned
        expect(presenter.redirect_to_dashboard?).to be_truthy
      end
    end

    context 'when there is a single attempt allowed' do
      it 'returns false when first opened' do
        # due date in the future
        assignment = create_assignment(due_date: 1.day.from_now)
        allow(presenter).to receive(:assignment).and_return(assignment)
        expect(presenter.redirect_to_dashboard?).to be_falsey

        # later that same week... due date in the past
        Timecop.travel(2.days.from_now) do
          presenter = TestPresenter.new(assessment_activity, student, section)
          allow(presenter).to receive(:assignment).and_return(assignment)
          expect(presenter.redirect_to_dashboard?).to be_falsey
        end
      end

      it 'returns true when the single attempt is used before the due date' do
        create_attempt(status_code: AttemptStatus::CODE_COMPLETED)
        assignment = create_assignment(due_date: 1.day.from_now)
        create_mock_score(pending?: true)
        # during the submit action, an 'activity_complete' parmam is used
        expect(presenter.redirect_to_dashboard?(_activity_complete = true)).to be_truthy
        # from the show action, no param is passed
        expect(presenter.redirect_to_dashboard?).to be_truthy

        # time passes and the instructor grades, student should get access
        Timecop.travel(2.days.from_now) do
          create_mock_score(pending?: false)
          presenter = TestPresenter.new(assessment_activity, student, section)
          # student reviews
          expect(presenter.redirect_to_dashboard?).to be_falsey
        end
      end
    end

    context 'when multiple attempts are allowed on an auto-graded activity' do
      it 'returns false when more attempts are available' do
        create_attempt(status_code: AttemptStatus::CODE_SUBMITTED)
        assignment = create_assignment(due_date: 1.day.from_now)
        allow(presenter).to receive(:assignment).and_return(assignment)
        # pending: false indicates an auto-graded activity
        create_mock_score(pending?: false)
        # submit action
        expect(presenter.redirect_to_dashboard?(_activity_complete = false)).to be_falsey
        #show action
        expect(presenter.redirect_to_dashboard?).to be_falsey
      end

      it 'returns false when the score is reset' do
        create_attempt(status_code: AttemptStatus::CODE_RESET)
        assignment = create_assignment(due_date: 1.day.from_now)
        allow(presenter).to receive(:assignment).and_return(assignment)
        # when a score is reset, pending is false and submitted_at is nil
        create_mock_score(submitted_at: nil, pending?: false, action: {type: 'reset_work'})
        expect(presenter.redirect_to_dashboard?).to be_falsey
      end

      it 'returns false when an unsubmitted score is dropped' do
        assignment = create_assignment(due_date: 1.day.from_now)
        allow(presenter).to receive(:assignment).and_return(assignment)
        create_mock_score(submitted_at: nil, pending?: false, action: {type: 'drop_score'})
        expect(presenter.redirect_to_dashboard?).to be_falsey
      end

      it 'returns false when a submitted score is dropped' do
        create_attempt(status_code: AttemptStatus::CODE_SUBMITTED)
        assignment = create_assignment(due_date: 1.day.from_now)
        allow(presenter).to receive(:assignment).and_return(assignment)
        # pending scores are never dropped, so pending is false here
        create_mock_score(submitted_at: 1.day.ago, pending?: false, action: {type: 'drop_score'})
        expect(presenter.redirect_to_dashboard?).to be_falsey
      end
    end
  end

  describe '#mapped_standards' do
    context 'when the standards need to be filtered by grade level of course' do
      let(:activity) { create(:activity) }
      let(:standard_asset) { create(:standard_asset, reference_id: activity.cms_activity_id) }
      let(:assessment_item) { create(:assessment_item_with_assessment) }
      let(:assessment_standard_asset) { create(:standard_asset, reference_id: assessment_item.id, reference_type: 'AssessmentItem' ) }
      let(:assessment) { assessment_item.assessment }
      let!(:standard_set) do
        StandardSet.create(
          vendor_guid: 'CF6A375C-67AD-11DF-AB5F-995D9DFF4B22',
          issuer: 'NGA Center/CCSSO',
          name: 'English Language Arts/Literacy',
          adopt_year: 2010,
          state: 'US,CC',
          acronym: 'CCSS',
          description: 'Common Core State Standards',
          display_name: 'CCSS'
        )
      end
      let(:standard_1) { create(:standard, number: 'ELA.6.R.2.3', standard_set:) }
      let(:standard_2) { create(:standard, number: 'ELA.7.R.2.3', standard_set:) }
      let(:add_info) do
        JSON.generate({  additional_info: { grade_levels: '9,10' } })
      end
      let(:wrong_grade_standard) { create(:standard, additional_info: add_info, standard_set:) }
      let!(:alignment_1) { create(:standard_alignment, standard_asset: assessment_standard_asset, standard: standard_1) }
      let!(:alignment_2) { create(:standard_alignment, standard_asset: assessment_standard_asset, standard: standard_2) }
      let!(:alignment_3) { create(:standard_alignment, standard_asset: assessment_standard_asset, standard: wrong_grade_standard) }
      let!(:alignment_4) { create(:standard_alignment, standard_asset: standard_asset, standard: standard_2) }
      let!(:alignment_5) { create(:standard_alignment, standard_asset: standard_asset, standard: wrong_grade_standard) }

      before do
        allow(assessment).to receive(:standards_test?).and_return(true)
        allow(assessment).to receive(:standard_assets).and_return([assessment_standard_asset])
        allow(course.program).to receive(:standard_grade_levels).and_return(['6', '7', '8'])
        allow(course).to receive(:standard_sets).and_return([standard_set])
      end

      it 'returns only the matching standards for an assessment item standard asset' do
        stds_presenter = TestPresenter.new(assessment, student, section)
        results = stds_presenter.mapped_standards(course)
        results.each do |std_set, standards|
          expect(std_set).to eq(standard_set.display_name)
          expect(standards.count).to eq 2
          expect(standards.pluck('id')).to_not include(wrong_grade_standard.id)
        end
      end

      it 'returns only the matching standards for an activity standard asset' do
        stds_presenter = TestPresenter.new(activity, student, section)
        results = stds_presenter.mapped_standards(course)
        results.each do |std_set, standards|
          expect(std_set).to eq(standard_set.display_name)
          expect(standards.count).to eq 1
          expect(standards.pluck('id')).to_not include(wrong_grade_standard.id)
        end
      end
    end
  end
end

describe Attempt do
  let(:student_1) { build_stubbed(:student) }
  let(:student_2) { build_stubbed(:student) }
  let(:section) { build_stubbed(:section) }
  let(:lesson) { create(:lesson_with_toc_entries) }
  let(:activity) { create(:activity, lesson: lesson, cdn: false) }
  let(:content_rev1_id) { activity.cms_revision_id }
  let(:content_rev1) do
    '<activity activity_type="open_ended" language="es" title="sample_open_ended_title">
      <dl>instructions_go_here</dl>
      <items>
        <item>
          <prompt>prompt_for_question_1</prompt>
        </item>
        <item>
          <prompt>prompt_for_question_2</prompt>
        </item>
      </items>
    </activity>'
  end
  let(:content_rev2_id) { activity.cms_revision_id + 1 }
  let(:content_rev2) do
    '<activity activity_type="open_ended" language="es" title="sample_open_ended_title">
      <dl>instructions_go_here</dl>
      <items>
        <item>
          <prompt>prompt_for_question_1</prompt>
        </item>
      </items>
    </activity>'
  end

  before do
    # create an activity with 2 revisions
    activity.content = content_rev1
    @recycle_bin << activity.content_filepath
    activity.save

    Activity.last.tap do |a|
      a.cms_revision_id += 1
      a.content = content_rev2
      @recycle_bin << a.content_filepath
      a.save
    end
  end

  describe '#all_questions_have_scores?' do
    context 'when a student has completed the first revision' do
      let(:attempt1) do
        create(:attempt, activity: Activity.last,
                         user: student_1,
                         section: section,
                         cms_revision_id: content_rev1_id)
      end
      let(:feedback_items) do
        [build_stubbed(:feedback_item, question_label: 'question_01',
                                       points_earned: 10),
         build_stubbed(:feedback_item, question_label: 'question_02',
                                       points_earned: 9)]
      end

      it 'returns false when only 1 question is graded' do
        allow(attempt1).to receive(:feedback_items).and_return([feedback_items[0]])
        expect(attempt1.all_questions_have_scores?).to be_falsey
      end

      it 'returns true when all questions are graded' do
        allow(attempt1).to receive(:feedback_items).and_return(feedback_items)
        expect(attempt1.all_questions_have_scores?).to be_truthy
      end

    end
  end

  describe '#valid_submission?' do
    context 'when the student has completed the first revision' do
      let(:attempt1) do
        create(:attempt, activity: Activity.last,
                         user: student_1,
                         section: section,
                         cms_revision_id: content_rev1_id)
      end

      let(:full_submission_results) do
        {'question_01' => 'blah', 'question_02' => 'blah' }
      end

      let(:one_answer_results) do
        {'question_01' => 'blah'}
      end

      it 'returns false when only one question is answered' do
        results = attempt1.send(:valid_submission?, one_answer_results)
        expect(results).to be_falsey
      end

      it 'returns true when all questions are answered' do
        results = attempt1.send(:valid_submission?, full_submission_results)
        expect(results).to be_truthy
      end
    end
  end

  describe '#process_instructor_grading' do
    context 'when the student has completed the first revision' do
      let!(:score_action) do
        build_stubbed(:gb_score_action, activity: activity,
                                        user: student_1,
                                        section: section,
                                        school_id: 123,
                                        summation: {points_earned: 0.0,
                                                    pending: true,
                                                    points_possible: 20,
                                                    submitted_at: Time.now})
      end
      let(:instructor_grading) { double(::Gradebook::InstructorGrading, process: true) }
      let(:feedback_items) do
        [build_stubbed(:feedback_item, question_label: 'question_01',
                                       points_earned: 10),
         build_stubbed(:feedback_item, question_label: 'question_02',
                                       points_earned: 9)]
      end
      let(:attempt1) do
        create(:attempt, activity: Activity.last,
                         user: student_1,
                         section: section,
                         cms_revision_id: content_rev1_id)
      end
      let(:cartridge_params) { { cartridge_consumer_guid: SecureRandom.uuid } }

      before do
        allow(feedback_items).to receive(:reload).and_return(feedback_items)
        allow(attempt1).to receive(:feedback_items).and_return(feedback_items)
        allow(::Gradebook::InstructorGrading)
          .to receive(:new)
          .and_return(instructor_grading)
        allow(attempt1).to receive(:all_questions_have_scores?).and_return(true)
      end

      it 'passes the correct points_earned to the grading module' do
        allow(GradebookEngine::GradebookAPI)
          .to receive(:find_score).and_return(score_action)
        expect(::Gradebook::InstructorGrading)
          .to receive(:new)
          .with(score_action, 19.0, reset_partial_pending: false)
          .and_return(instructor_grading)
        attempt1.process_instructor_grading(cartridge_params: cartridge_params)
      end
    end
  end
end

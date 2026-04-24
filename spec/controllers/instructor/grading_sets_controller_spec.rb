describe Instructor::GradingSetsController do
  shared_examples 'an action that finds and assigns the feedback items' do
    it 'should retrieve the feedback items and assign them' do
      expect(@grading_set).to receive(:feedback_for_student_on_question)
      allow(@grading_set).to receive(:grading_status_of_students).and_return({})
      do_request
    end
  end

  shared_examples 'an action that finds and assigns the grading style setting' do
    it 'should retrieve the grading_style setting and assign it' do
      expect(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return('valid_grading_style')
      do_request
      expect(assigns(:grading_style)).to eq('valid_grading_style')
    end
  end

  shared_examples 'an action that finds and assigns the spotcheck style setting' do
    it 'should retrieve the grading_style setting and assign it' do
      expect(@instructor).to receive(:setting).with(Setting::GradingTasks::SpotcheckStyle).and_return('valid_spotcheck_style')
      allow(@grading_set).to receive(:grading_status_of_students).and_return({})
      do_request
      expect(assigns(:spotcheck_style)).to eq('valid_spotcheck_style')
    end
  end

  shared_examples 'an action that finds and assigns the grading set and associated activity' do
    before do
      allow(@grading_set).to receive(:grading_status_of_students).and_return({})
    end

    it 'finds and assigns the grading set specified by the id param' do
      expect(GradingSet).to receive(:find).with(@grading_set.id.to_s).and_return(@grading_set)
      do_request
      expect(assigns(:grading_set)).to eq(@grading_set)
    end

    it 'redirect to best default path when the grading set does not belong to the current user' do
      allow(@grading_set).to receive(:owned_by?).and_return(false)
      allow(GradingSet).to receive(:find).and_return(@grading_set)
      expect(BestDefaultPath).to receive(:best_default_path).and_return('/redirect/to')
      do_request
      expect(response).to redirect_to '/redirect/to'
    end
  end

  shared_examples 'an action that sets up data for rubric grading' do
    let(:user_scores_for_grading_mock) { instance_double(UserScoresForGrading) }
    let(:presenter_mock) { instance_double(StudentByStudentPresenter, activity: @activity) }

    before do
      allow(@activity).to receive(:has_rubric?).and_return(true)
      allow(user_scores_for_grading_mock).to receive(:score_list).and_return([{ foo: 'bar' }])
      allow(user_scores_for_grading_mock).to receive(:comment_boxes).and_return([])
      allow(presenter_mock).to receive(:has_rubric?).and_return(true)
    end

    it 'creates the score data for the rubric grading app' do
      expect(UserScoresForGrading).to receive(:new).and_return(user_scores_for_grading_mock)
      do_request
    end

    it 'assigns user_scores_for_rubric_grading' do
      allow(UserScoresForGrading).to receive(:new).and_return(user_scores_for_grading_mock)
      do_request
      expect(assigns(:user_scores_json)).to eq([{ foo: 'bar' }].to_json)
    end

    it 'assigns comment_boxes' do
      allow(UserScoresForGrading).to receive(:new).and_return(user_scores_for_grading_mock)
      do_request
      expect(assigns(:comment_boxes)).to eq([])
    end
  end

  shared_examples 'an action that does not set up data for rubric grading' do
    let(:presenter_mock) { instance_double(StudentByStudentPresenter, activity: @activity) }

    it 'does not create the score data for the rubric grading app' do
      allow(@activity).to receive(:has_rubric?).and_return(false)
      allow(presenter_mock).to receive(:has_rubric?).and_return(false)
      allow(UserScoresForGrading).to receive(:new)
      expect(UserScoresForGrading).not_to have_received(:new)
      do_request
    end
  end

  describe 'an action that assigns the current question or current student', shared: true do
    context 'when grading style is set to question by question,' do
      before do
        allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return(Setting::GradingTasks::GradingStyle::BY_QUESTION)
        allow(@grading_set).to receive(:feedback_for_student_on_question).and_return(nil)
      end
    end

    context 'when grading style is not set to question by question,' do
      before do
        allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return(Setting::GradingTasks::GradingStyle::BY_STUDENT)
      end
    end
  end

  describe '#edit_confirm' do
    before do
      populate_instructor_program_and_focus
      lesson = build_stubbed(:lesson_with_toc_entries)
      allow(lesson).to receive(:program).and_return(@program)
      allow(lesson).to receive(:strand_for_toc_location).and_return(create(:toc_entry))
      @activity = build_stubbed(:activity, lesson: lesson, cms_revision_id: 1)
      allow(@activity).to receive(:has_rubric?).and_return(false)
      allow(Activity).to receive(:find).and_return(@activity)
      @attempt = build_stubbed(:attempt, cms_revision_id: 1)
      allow(Attempt).to receive(:active_attempt).and_return(@attempt)
      allow(@attempt).to receive(:activity_version).and_return(@activity)

      @student_1 = build_stubbed(:student)
      @student_2 = build_stubbed(:student)
      @question_1 = double('Question', label: 'question_01')
      @question_2 = double('Question', label: 'question_02')
      allow(@activity).to receive(:instructor_graded_questions).and_return([@question_1, @question_2])
      allow(@activity).to receive(:cms_revision_id=)
      allow(@activity).to receive(:has_mixed_grading_method?).and_return(false)
      @grading_set = double(GradingSet, id: 123, activity_id: @activity.id, students_to_grade: [@student_1, @student_2])
      allow(@grading_set).to receive(:activity).and_return(@activity)
      allow(@grading_set).to receive(:grading_status_of_students).and_return({})
      allow(@grading_set).to receive(:owned_by?).and_return(true)
      allow(GradingSet).to receive(:find).and_return(@grading_set)
    end

    def do_request(params = {})
      get :edit_confirm, params: { program_id: @program.id, id: @grading_set.id }.merge(params)
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'
    it_should_behave_like 'an action that finds and assigns the grading set and associated activity'
    it_should_behave_like 'an action that assigns contextual help'

    it 'assigns the activity from the presenter' do
      do_request

      expect(assigns(:activity)).not_to be_nil
      expect(assigns(:activity)).to eq assigns(:presenter).activity
    end

    context 'when grading question by question' do
      let(:section) { build_stubbed(:section) }
      let(:student) { build_stubbed(:student) }

      before do
        allow(@controller).to receive(:question_by_question?).and_return(true)
        current_focus = Focus.new(@instructor, @program, {})
        allow(Focus).to receive(:new).and_return(current_focus)
        allow(current_focus).to receive(:sections).and_return([section])
      end

      it 'constructs a question by question presenter' do
        presenter_mock = instance_double(QuestionByQuestionPresenter, activity: @activity)
        allow(presenter_mock).to receive(:prepare).and_return(presenter_mock)
        expect(QuestionByQuestionPresenter).to receive(:new).with(@instructor,
                                                                  @grading_set,
                                                                  @program,
                                                                  [section],
                                                                  anything,
                                                                  anything).and_return(presenter_mock)
        expect(QuestionByQuestionViewManager).to receive(:new)
        do_request
      end
    end

    context 'when grading student by student' do
      let(:section) { build_stubbed(:section) }
      let(:student) { build_stubbed(:student) }
      let(:presenter_mock) { instance_double(StudentByStudentPresenter, activity: @activity) }

      before do
        allow(@controller).to receive(:question_by_question?).and_return(false)
        current_focus = Focus.new(@instructor, @program, {})
        allow(Focus).to receive(:new).and_return(current_focus)
        allow(current_focus).to receive(:sections).and_return([section])
        allow(presenter_mock).to receive(:prepare).and_return(presenter_mock)
      end

      it 'constructs a student by student presenter' do
        allow(presenter_mock).to receive(:has_rubric?).and_return(false)
        allow(StudentByStudentPresenter).to receive(:new).and_return(presenter_mock)
        do_request
        expect(StudentByStudentPresenter).to have_received(:new)
         .with(
           @instructor,
           @grading_set,
           @program,
           [section],
           anything,
           anything,
           anything
         )
      end

      it 'constructs a student by student view manager' do
        allow(presenter_mock).to receive(:has_rubric?).and_return(false)
        allow(StudentByStudentViewManager).to receive(:new)
        do_request
        expect(StudentByStudentViewManager).to have_received(:new)
      end

      context 'with a rubric activity' do
        it_behaves_like 'an action that sets up data for rubric grading'
      end

      context 'with a non-rubric activity' do
        it_behaves_like 'an action that does not set up data for rubric grading'
      end
    end
  end

  describe '#edit' do
    before do
      populate_instructor_program_and_focus
      allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return('valid_grading_style')
      allow(@instructor).to receive(:setting).with(Setting::GradingTasks::SpotcheckStyle).and_return('manual')

      recording = build_stubbed(:recording, user: @instructor)
      lesson = build_stubbed(:lesson_with_toc_entries)
      allow(lesson).to receive(:program).and_return(@program)
      allow(lesson).to receive(:strand_for_toc_location).and_return(build_stubbed(:toc_entry))

      @activity = build_stubbed(:activity, lesson: lesson, cms_revision_id: 1)
      allow(@activity).to receive(:has_rubric?).and_return(false)
      @question_1 = double('Question', label: 'question_01')
      @question_2 = double('Question', label: 'question_02')
      allow(@activity).to receive(:instructor_graded_questions).and_return([@question_1, @question_2])
      allow(@activity).to receive(:has_mixed_grading_method?).and_return(false)
      allow(@activity).to receive(:has_multiple_versions?).and_return(false)
      allow(@activity).to receive(:cms_revision_id=)
      allow(@activity).to receive(:questions).and_return([@question_1, @question_2])
      allow(Activity).to receive(:find).and_return(@activity)

      @attempt = build_stubbed(:attempt, cms_revision_id: 1)
      allow(Attempt).to receive(:active_attempt).and_return(@attempt) #nick
      allow(@attempt).to receive(:activity_version).and_return(@activity)  #nick

      @student_1 = build_stubbed(:student)
      @student_2 = build_stubbed(:student)

      @grading_set = double(GradingSet, id: 123, activity_id: @activity.id, students_to_grade: [@student_1, @student_2])
      allow(GradingSet).to receive(:find).and_return(@grading_set)
      allow(@grading_set).to receive(:grading_status_of_students).and_return({})
      allow(@grading_set).to receive(:grading_status_of_questions).and_return({})
      allow(@grading_set).to receive(:feedback_for_student_on_question).and_return(double(FeedbackItem, recording: recording))
      allow(@grading_set).to receive(:activity).and_return(@activity)
      allow(@grading_set).to receive(:students_graded).and_return([])
      allow(@grading_set).to receive(:owned_by?).and_return(true)
    end

    def do_request(params = {})
      get :edit, params: { program_id: @program.id, id: @grading_set.id, commit: 'Next' }.merge(params)
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'

    it_should_behave_like 'an action that finds and assigns the grading style setting'
    it_should_behave_like 'an action that finds and assigns the spotcheck style setting'
    it_should_behave_like 'an action that finds and assigns the grading set and associated activity'

    it_should_behave_like 'an action that assigns contextual help'

    it_should_behave_like 'an action that assigns allowed file extensions'

    it 'assigns angular controller' do
      do_request
      expect(assigns(:angular_controller)).to eq('instructorActivityRequestsCtrl')
    end

    it 'assigns the activity from the presenter' do
      do_request

      expect(assigns(:activity)).not_to be_nil
      expect(assigns(:activity)).to eq assigns(:presenter).activity
    end

    context 'for question_by_question' do
      before do
        @section = build_stubbed(:section)
        @student = build_stubbed(:student)
        allow(@student).to receive(:current_section_in_program).and_return(@section)
        allow(@grading_set).to receive(:students_to_grade).and_return([@student])
        allow(@grading_set).to receive(:feedback_for_student_on_question).and_return(nil)
        allow(@grading_set).to receive(:activity).and_return(@activity)
        allow(@grading_set).to receive(:grading_status_of_students).and_return({})
        allow(@controller).to receive(:question_by_question?).and_return(true)

        allow(@instructor).to receive(:setting).and_return(Setting::GradingTasks::GradingStyle::BY_QUESTION)
        current_focus = Focus.new(@instructor, @program, {})
        allow(Focus).to receive(:new).and_return(current_focus)
        allow(current_focus).to receive(:sections).and_return([@section])
        allow(current_focus).to receive(:students).and_return([@student])
        allow(Attempt).to receive(:find_submitted_attempts_for_activity_and_students).and_return({})
      end

      it 'constructs a question by question presenter' do
        presenter_mock = double(
          'QuestionByQuestionPresenter',
          student_attempts: [],
          activity: @activity,
          page_title: 'Grading Question by Question',
          has_nothing_to_grade?: true
        )
        allow(presenter_mock).to receive(:prepare).and_return(presenter_mock)
        expect(QuestionByQuestionPresenter).to receive(:new).with(
          @instructor,
          @grading_set,
          @program,
          [@section],
          anything,
          anything
        ).and_return(presenter_mock)
        expect(QuestionByQuestionViewManager).to receive(:new)

        do_request
      end

      context 'when no student answers are found' do
        it 'informs the instructors that results are unavailable' do
          do_request
          expect(flash[:error]).to eq(
            'There are currently no submissions to review.'
          )
        end
      end

      context 'when the student answers (attempts) all have the same cms_revision_id' do
        it 'should allow the instructor to grade question by question' do
          student_answer_1 = build_stubbed(:attempt, cms_revision_id: 1, user_id: @student_1.id)
          student_answer_2 = build_stubbed(:attempt, cms_revision_id: 1, user_id: @student_2.id)
          allow(Attempt).to receive(:find_submitted_attempts_for_activity_and_students).and_return(@student_1.id.to_s => student_answer_1, @student_2.id.to_s => student_answer_2)
          expect(@controller).to receive(:render).twice
          do_request
        end
      end

      context "when the student answers (attempts) do not have the same cms_revision_id" do
        before(:each) do
          student_answer_1 = build_stubbed(:attempt, cms_revision_id: 2, user_id: @student_1.id)
          student_answer_2 = build_stubbed(:attempt, cms_revision_id: 1, user_id: @student_2.id)
          allow(Attempt).to receive(:find_submitted_attempts_for_activity_and_students).and_return(@student_1.id.to_s => student_answer_1, @student_2.id.to_s => student_answer_2)
          allow(@activity).to receive(:activity_type).and_return('')
          allow(@activity).to receive(:grading_method).and_return('')
          allow(@activity).to receive(:content_object).and_return(
            double('ContentObject', has_rubric?: false)
          )
          presenter_mock = double('QuestionByQuestionPresenter',
                                  activity: @activity,
                                  page_title: 'Grading Question by Question',
                                  student_attempts: [])
          allow(presenter_mock).to receive(:prepare).and_return(presenter_mock)
        end

        it 'should not allow the instructor to grade question by questions' do
          expect(@controller).to receive(:redirect_to).with(instructor_grading_styles_path(@program, @activity))
          do_request
        end

        it 'should display a flash warning informing the instructor question by question is disabled' do
          do_request
          expect(flash[:warning]).to eq('Different versions of this activity exist. You may only grade student by student.')
        end
      end
    end

    context 'for student_by_student' do
      before do
        @section = build_stubbed(:section)
        @student = build_stubbed(:student)
        allow(@student).to receive(:most_relevant_section).and_return(@section)
        allow(@student).to receive(:current_section_in_program).and_return(@section)
        allow(@grading_set).to receive(:students_to_grade).and_return([@student])
        allow(@grading_set).to receive(:activity).and_return(@activity)
        allow(@grading_set).to receive(:grading_status_of_students).and_return({})
        allow(@controller).to receive(:question_by_question?).and_return(false)
        allow(@controller).to receive(:student_by_student?).and_return(true)

        allow(@instructor).to receive(:setting).and_return(Setting::GradingTasks::GradingStyle::BY_STUDENT)
        current_focus = Focus.new(@instructor, @program, {})
        allow(Focus).to receive(:new).and_return(current_focus)
        allow(current_focus).to receive(:sections).and_return([@section])
        allow(current_focus).to receive(:students).and_return([@student])
        allow(@activity).to receive(:has_mixed_grading_method?).and_return(false)
        allow(@activity).to receive(:has_rubric?).and_return(false)
        allow(Attempt).to receive(:find_submitted_attempts_for_activity_and_students).and_return([])
      end

      it 'constructs a student by student presenter' do
        presenter_mock = double(
          'StudentByStudentPresenter',
          student_attempts: [],
          activity: @activity,
          page_title: 'Grading Student by Student',
          has_nothing_to_grade?: true
        )
        allow(presenter_mock).to receive(:prepare).and_return(presenter_mock)
        allow(presenter_mock).to receive(:has_rubric?)
        expect(StudentByStudentPresenter).to receive(:new).with(
          @instructor,
          @grading_set,
          @program,
          [@section],
          anything,
          anything,
          anything
        ).and_return(presenter_mock)

        do_request
      end

      context 'with a rubric activity' do
        it_behaves_like 'an action that sets up data for rubric grading'
      end

      context 'with a non-rubric activity' do
        it_behaves_like 'an action that does not set up data for rubric grading'
      end

      context 'when multiple versions of one activity exist' do
        before do
          @activity_version_1 = build_stubbed(:activity)
          @activity_version_2 = build_stubbed(:activity, cms_activity_id: @activity_version_1.cms_activity_id)

          student_answer_1 = build_stubbed(:attempt, cms_revision_id: @activity_version_1.cms_revision_id,
                                                     cms_activity_id: @activity_version_1.cms_activity_id,
                                                     user_id: @student_1.id,
                                                     activity: @activity_version_1)
          student_answer_2 = build_stubbed(:attempt, cms_revision_id: @activity_version_2.cms_revision_id,
                                                     cms_activity_id: @activity_version_2.cms_activity_id,
                                                     user_id: @student_2.id,
                                                     activity: @activity_version_2)
          allow(@grading_set).to receive(:students_to_grade).and_return([@student_1, @student_2])
          allow(@student_1).to receive(:most_relevant_section).and_return(@section)
          allow(@grading_set).to receive(:grading_status_of_students).and_return({})
          allow(Attempt).to receive(:find_submitted_attempts_for_activity_and_students).and_return(@student_1.id.to_s => student_answer_1, @student_2.id.to_s => student_answer_2)
        end

        it 'should allow grading student by student' do
          expect(@controller).to receive(:render).twice
          do_request
        end
      end

      context 'when there is a missing attempt' do
        let(:program) { build_stubbed(:program) }
        let(:student_1) { build_stubbed(:student) }
        let(:student_2) { build_stubbed(:student) }
        let(:student_answer_1) { build_stubbed(:attempt, user_id: student_1.id, activity: @activity) }
        let(:student_answer_2) { build_stubbed(:attempt, user_id: student_2.id, activity: @activity) }
        let(:error) { 'An error has occured. Please click on "Start Grading".' }

        it 'redirects to the edit_confirm action with a flash message' do
          allow(Program).to receive(:find_by_id).and_return(program)
          allow(Attempt).to receive(:find_submitted_attempts_for_activity_and_students).and_return(@student_1.id.to_s => student_answer_1)
          do_request
          expect(response).to redirect_to instructor_grading_styles_path(program, @activity)
          expect(flash[:error]).to include error
        end
      end

      context ' when activity is multi-type ' do
        before do
          @section = build_stubbed(:section)
          @student = build_stubbed(:student)
          allow(@student).to receive(:most_relevant_section).and_return(@section)

          allow(@grading_set).to receive(:students_to_grade).and_return([@student])
          allow(@grading_set).to receive(:activity).and_return(@activity)
          allow(@grading_set).to receive(:grading_status_of_students).and_return({})

          allow(@instructor).to receive(:setting).and_return(Setting::GradingTasks::GradingStyle::BY_STUDENT)
          current_focus = Focus.new(@instructor, @program, {})
          allow(Focus).to receive(:new).and_return(current_focus)
          allow(current_focus).to receive(:sections).and_return([@section])
          allow(current_focus).to receive(:students).and_return([@student])

          allow(@activity).to receive(:has_mixed_grading_method?).and_return(true)

          @classwork = Classwork.new(@student, @section)
          @attempt = build_stubbed(:attempt)
          allow(@attempt).to receive(:results).and_return({})

          allow(@classwork).to receive(:find_active_attempt).with(@activity).and_return(@attempt)
          allow(Classwork).to receive(:new).and_return(@classwork)
        end
      end
    end
  end

  describe '#update' do
    let(:grading_submission) {
      double('GradingSubmission',
        process_submission: true,
        invalid_scores: [],
        concurrent_enrollment_failures?: false,
        all_students_failed_ce?: false,
        concurrent_enrollment_warning_message: nil
      )
    }

    before do
      @section = create(:section)
      populate_instructor_program_and_focus(sections: [@section])
      allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return('valid_grading_style')
      @recording = build_stubbed(:recording, user: @instructor)

      lesson = build_stubbed(:lesson_with_toc_entries)
      allow(lesson).to receive(:program).and_return(@program)
      allow(lesson).to receive(:strand_for_toc_location).and_return(build_stubbed(:toc_entry))
      @activity = build_stubbed(:activity, lesson: lesson, cms_revision_id: 1)
      allow(@activity).to receive(:has_rubric?).and_return(false)
      @question_1 = double('Question', label: 'question_01', points_possible: 10)
      @question_2 = double('Question', label: 'question_02', points_possible: 10)
      allow(@activity).to receive(:instructor_graded_questions).and_return([@question_1, @question_2])
      allow(@activity).to receive(:cms_revision_id=)
      allow(@activity).to receive(:has_mixed_grading_method?).and_return(false)
      allow(@activity).to receive(:questions).and_return([@question_1, @question_2])
      allow(Activity).to receive(:find).and_return(@activity)
      @attempt = build_stubbed(:attempt, cms_revision_id: 1)
      allow(Attempt).to receive(:active_attempt).and_return(@attempt) #nick
      allow(@attempt).to receive(:activity_version).and_return(@activity)  #nick

      @student_1 = create(:student)
      @student_2 = create(:student)

      @grading_set = double(GradingSet, id: 123, activity_id: @activity.id, students_to_grade: [@student_1, @student_2])
      allow(@grading_set).to receive(:update_state)
      allow(@grading_set).to receive(:feedback_for_student_on_question).and_return(@feedback)
      allow(@grading_set).to receive(:activity).and_return(@activity)
      allow(@grading_set).to receive(:grading_status_of_students).and_return({})
      allow(@grading_set).to receive(:owned_by?).and_return(true)
      allow(GradingSet).to receive(:find).and_return(@grading_set)

      @feedback = double(FeedbackItem)
      allow(@feedback).to receive(:inline_corrections)
      allow(@feedback).to receive(:recording).and_return(@recording)
      allow(@controller).to receive(:has_instructor_markup?).and_return(true)
      allow(FeedbackItem).to receive(:submit)
      allow(InstructorGradingSubmission).to receive(:new).and_return(grading_submission)
      allow_any_instance_of(QuestionByQuestionPresenter).to receive(:submit_students).and_return([@student_1, @student_2])
    end

    def do_request(params = {})
      put :update, params: { program_id: @program.id, id: @grading_set.id, commit: 'Next' }.merge(params)
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'

    it_should_behave_like 'an action that finds and assigns the grading style setting'
    it_should_behave_like 'an action that finds and assigns the spotcheck style setting'
    it_should_behave_like 'an action that finds and assigns the grading set and associated activity'

    it_should_behave_like 'an action that assigns contextual help'

    it 'updates grading set state' do
      expect(@grading_set).to receive(:update_state)
      do_request()
    end

    it 'sets a flash notice when finished' do
      response_id = "#{@question_1.label}_student_#{@student_1.id}"
      do_request(:question_label => @question_1.label, "score_for_#{response_id}" => @expected_points_earned,
                 "inline_corrections_for_#{response_id}" => @expected_corrections,
                 "comment_for_#{response_id}" => @expected_comment,
                 :commit => 'Done')
      expect(flash[:notice]).to include 'has been successfully graded.'
    end

    it 'does not set a flash notice if not finished' do
      response_id = "#{@question_1.label}_student_#{@student_1.id}"
      do_request(:question_label => @question_1.label, "score_for_#{response_id}" => @expected_points_earned,
                 "inline_corrections_for_#{response_id}" => @expected_corrections,
                 "comment_for_#{response_id}" => @expected_comment,
                 :commit => 'Save & Next >')
      expect(flash[:notice]).to be_nil
    end

    context 'when grading style is set to question by question,' do
      before do
        allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return(Setting::GradingTasks::GradingStyle::BY_QUESTION)
        allow(@grading_set).to receive(:students_to_grade).and_return([@student_1])
      end

      context 'when there are no validation errors,' do
        let(:grading_submission) {
          double('GradingSubmission',
            process_submission: true,
            invalid_scores: [],
            concurrent_enrollment_failures?: false,
            all_students_failed_ce?: false,
            concurrent_enrollment_warning_message: nil
          )
        }

        before do
          @expected_points_earned = (@question_1.points_possible - 1).to_s
          @expected_corrections   = 'inline_corrections_text'
          @expected_comment       = 'comment_text'
        end

        it 'should redirect to the next question when the Next button is pushed' do
          response_id = "#{@question_1.label}_student_#{@student_1.id}"
          do_request(:question_label => @question_1.label, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => 'Save & Next >')
          expect(response).to redirect_to(edit_instructor_grading_set_path(@program, @grading_set, question_label: @question_2.label))
        end

        it 'should redirect to the previous question when previous button is pushed' do
          response_id = "#{@question_2.label}_student_#{@student_1.id}"
          do_request(:question_label => @question_2.label, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => '< Save & Previous')
          expect(response).to redirect_to(edit_instructor_grading_set_path(@program, @grading_set, question_label: @question_1.label))
        end

        it 'should redirect to a question chosen from the progress bar' do
          response_id = "#{@question_2.label}_student_#{@student_1.id}"
          do_request(:question_label => @question_2.label, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :jump_to => @question_1.label)
          expect(response).to redirect_to(edit_instructor_grading_set_path(@program, @grading_set, question_label: @question_1.label))
        end

        it 'should redirect to the To Do list when finished' do
          response_id = "#{@question_2.label}_student_#{@student_1.id}"
          do_request(:question_label => @question_2.label, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => 'Done')
          expect(response).to redirect_to(instructor_grading_tasks_assignments_path(@program))
        end

        it "redirects to the To Do list if user hits done but we're not on the last question" do
          response_id = "#{@question_1.label}_student_#{@student_1.id}"
          do_request(:question_label => @question_1.label, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => 'Done')
          expect(response).to redirect_to(instructor_grading_tasks_assignments_path(@program))
        end
      end
    end

    context 'when grading style is set to student by student,' do
      before do
        allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return(Setting::GradingTasks::GradingStyle::BY_STUDENT)
        allow(@grading_set).to receive(:students_to_grade).and_return([@student_1, @student_2])
        allow(@grading_set).to receive(:grading_status_of_students).and_return([])
        allow(@grading_set).to receive(:grading_status_of_students).and_return({})
        allow(@activity).to receive(:instructor_graded_questions).and_return([@question_1])
      end
      context 'with a rubric activity' do
        it_behaves_like 'an action that sets up data for rubric grading'
      end

      context 'with a non-rubric activity' do
        it_behaves_like 'an action that does not set up data for rubric grading'
      end

      context 'when there are no validation errors,' do
        before do
          @expected_points_earned = (@question_1.points_possible - 1).to_s
          @expected_corrections   = 'inline_corrections_text'
          @expected_comment       = 'comment_text'
        end

        it 'should redirect to the next student when the Next button is pushed' do
          response_id = "#{@question_1.label}_student_#{@student_1.id}"
          do_request(:student_id => @student_1.id, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => 'Save & Next >')
          expect(response).to redirect_to(edit_instructor_grading_set_path(@program, @grading_set, student_id: @student_2.id))
        end

        it 'should redirect to the previous student when previous button is pushed' do
          response_id = "#{@question_1.label}_student_#{@student_2.id}"
          do_request(:student_id => @student_2.id, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => '< Save & Previous')
          expect(response).to redirect_to(edit_instructor_grading_set_path(@program, @grading_set, student_id: @student_1.id))
        end

        it 'should redirect to the student chosen from the progress bar' do
          response_id = "#{@question_1.label}_student_#{@student_2.id}"
          do_request(:student_id => @student_2.id, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :jump_to => @student_1.id.to_s)
          expect(response).to redirect_to(edit_instructor_grading_set_path(@program, @grading_set, student_id: @student_1.id.to_s))
        end

        it 'should redirect to the To Do list when finished' do
          response_id = "#{@question_1.label}_student_#{@student_2.id}"
          do_request(:student_id => @student_2.id, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => 'Done')
          expect(response).to redirect_to(instructor_grading_tasks_assignments_path(@program))
        end

        it "redirects to the To Do list if user hits done but we're not on the last student" do
          response_id = "#{@question_1.label}_student_#{@student_1.id}"
          do_request(:student_id => @student_1.id, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => 'Done')
          expect(response).to redirect_to(instructor_grading_tasks_assignments_path(@program))
        end
      end
    end

    context 'when the grading style is spotcheck' do
      before do
        allow(@instructor).to receive(:setting).with(Setting::GradingTasks::GradingStyle).and_return(Setting::GradingTasks::GradingStyle::SPOTCHECK)
        allow(@grading_set).to receive(:students_to_grade).and_return([@student_1, @student_2])

        allow(@grading_set).to receive(:grading_status_of_students)
        allow(@grading_set).to receive(:grading_status_of_students).and_return({})
        allow(@activity).to receive(:instructor_graded_questions).and_return([@question_1])
        @expected_points_earned = (@question_1.points_possible - 1).to_s
        @expected_corrections   = 'inline_corrections_text'
        @expected_comment       = 'comment_text'
      end

      context 'when the student is the last student in the list' do
        it 'sets show_finish_spotchecking so the show finish spotchecking modal gets rendered ' do
          response_id = "#{@question_1.label}_student_#{@student_2.id}"
          do_request(:student_id => @student_2.id, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => 'Save & Next >')
          expect(assigns(:show_finish_spotchecking)).to be_truthy
        end
      end

      context 'when the show finish spotchecking modal is rendered' do
        it 'should create spotcheck records' do
          response_id = "#{@question_1.label}_student_#{@student_2.id}"
          do_request(:student_id => @student_2.id, "score_for_#{response_id}" => @expected_points_earned,
                     "inline_corrections_for_#{response_id}" => @expected_corrections,
                     "comment_for_#{response_id}" => @expected_comment,
                     :commit => 'Save & Next >')

          spotcheck_count_for_student_2 = StudentSpotcheckCount.find_by(user_id: @student_2.id,
                                                                        section_id: @section.id)
          expect(spotcheck_count_for_student_2.count).to eq(1)
        end
      end
    end

    context 'when handling AI chat feedback' do
      let(:ai_chat_feedback) { { flaggedItems: [], additionalFeedback: "Test feedback" }.to_json }
      let(:feedback_processor) { instance_double(AI::ChatFeedbackProcessor, process!: true) }

      before do
        allow(@activity).to receive(:ai_virtual_chat?).and_return(true)
        allow(AI::ChatFeedbackProcessor).to receive(:new).and_return(feedback_processor)
      end

      it 'processes AI chat feedback when present' do
        expect(AI::ChatFeedbackProcessor).to receive(:new).with(
          params_json: ai_chat_feedback,
          program: @program,
          activity: @activity,
          instructor: @instructor
        ).and_return(feedback_processor)

        expect(feedback_processor).to receive(:process!)

        do_request(ai_chat_feedback: ai_chat_feedback)
      end

      it 'does not process AI chat feedback when activity is not ai_virtual_chat' do
        allow(@activity).to receive(:ai_virtual_chat?).and_return(false)

        expect(AI::ChatFeedbackProcessor).not_to receive(:new)

        do_request(ai_chat_feedback: ai_chat_feedback)
      end

      it 'does not process AI chat feedback when feedback params are not present' do
        expect(AI::ChatFeedbackProcessor).not_to receive(:new)

        do_request(ai_chat_feedback: nil)
      end

      it 'continues normal grading process after processing AI feedback' do
        do_request(ai_chat_feedback: ai_chat_feedback)

        expect(response).to redirect_to(instructor_grading_tasks_assignments_path(@program))
      end
    end

    context 'with concurrent enrollment scenarios' do
      before do
        allow(@presenter).to receive(:last_item?).and_return(true)
        allow(@presenter).to receive(:done?).and_return(true)
      end

      context 'when some students have concurrent enrollment failures' do
        let(:grading_submission) {
          double('GradingSubmission',
            process_submission: true,
            invalid_scores: [],
            concurrent_enrollment_failures?: true,
            all_students_failed_ce?: false,
            concurrent_enrollment_warning_message: 'John Doe had concurrent enrollment data inconsistency. Please focus to the individual section.'
          )
        }

        it 'sets warning flash message' do
          do_request

          expect(flash[:warning]).to eq('John Doe had concurrent enrollment data inconsistency. Please focus to the individual section.')
        end

        it 'also sets success flash message' do
          do_request

          expect(flash[:notice]).to eq("#{@activity.title} has been successfully graded.")
        end

        it 'redirects to assignments path' do
          do_request

          expect(response).to redirect_to(instructor_grading_tasks_assignments_path(@program))
        end
      end

      context 'when all students failed concurrent enrollment' do
        let(:grading_submission) {
          double('GradingSubmission',
            process_submission: true,
            invalid_scores: [],
            concurrent_enrollment_failures?: true,
            all_students_failed_ce?: true,
            concurrent_enrollment_warning_message: 'John Doe, Jane Smith had concurrent enrollment data inconsistency. Please focus to the individual section.'
          )
        }

        it 'sets error flash message' do
          do_request

          expect(flash[:error]).to eq('John Doe, Jane Smith had concurrent enrollment data inconsistency. Please focus to the individual section.')
        end

        it 'does not set success flash message' do
          do_request

          expect(flash[:notice]).to be_nil
        end

        it 'redirects to assignments path' do
          do_request

          expect(response).to redirect_to(instructor_grading_tasks_assignments_path(@program))
        end
      end

      context 'when no concurrent enrollment failures' do
        let(:grading_submission) {
          double('GradingSubmission',
            process_submission: true,
            invalid_scores: [],
            concurrent_enrollment_failures?: false,
            all_students_failed_ce?: false,
            concurrent_enrollment_warning_message: nil
          )
        }

        it 'shows normal success message' do
          do_request

          expect(flash[:notice]).to eq("#{@activity.title} has been successfully graded.")
          expect(flash[:warning]).to be_nil
          expect(flash[:error]).to be_nil
        end
      end
    end
  end
end

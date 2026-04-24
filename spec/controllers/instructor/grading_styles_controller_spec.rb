describe Instructor::GradingStylesController do
  describe '#index' do
    let(:section) { build_stubbed(:section) }
    let(:activity) { create(:activity) }

    before do
      populate_instructor_program_and_focus(sections: [create(:section)])

      @presenter = double(InstructorGradingStylesPresenter).as_null_object
      @activity_presenter = double(StudentActivityPresenter).as_null_object
      allow(@presenter).to receive(:section).and_return(section)
      allow(@presenter).to receive(:activity).and_return(activity)
      allow(InstructorGradingStylesPresenter).to receive(:new).and_return(@presenter)
      allow(StudentActivityPresenter).to receive(:new).and_return(@activity_presenter)
    end

    def do_request
      get :index, params: { program_id: @program.id, activity_id: activity.id, task_type: 'bar' }
    end

    it_should_have_help
    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'
    it_should_behave_like 'an action that assigns contextual help'

    describe 'activity_presenter' do
      before do
        allow(controller).to receive(:current_user).and_return(@instructor)
      end

      it 'is created' do
        expect(StudentActivityPresenter).to receive(:new).and_return(@activity_presenter)
        do_request
      end

      it 'is assigned' do
        do_request
        expect(assigns(:activity_presenter)).to eql @activity_presenter
      end
    end

    describe 'the presenter' do
      before do
        allow(controller).to receive(:current_program).and_return(@program)
        allow(controller).to receive(:current_user).and_return(@instructor)
        allow(controller).to receive(:current_focus).and_return(@focus)

        @opts = {
          program: @program,
          instructor: @instructor,
          focus: @focus,
          activity_id: activity.id.to_s,
          task_type: 'bar'
        }
      end

      it 'is created' do
        expect(InstructorGradingStylesPresenter).to receive(:new).with(hash_including(@opts)).and_return(@presenter)
        do_request
      end

      it 'is assigned' do
        do_request
        expect(assigns(:presenter)).to eql @presenter
      end

      describe 'always' do
        it 'assigns the section' do
          allow(@presenter).to receive(:section).and_return(section)
          do_request
          expect(assigns(:section)).to eql section
        end

        it 'assigns the activity' do
          do_request
          expect(assigns(:activity)).to eql activity
        end

        it 'assigns the activity list header' do
          activity_list_header = double('activity list header')
          allow(@presenter).to receive(:activity_list_header).and_return(activity_list_header)
          do_request
          expect(assigns(:activity_list_header)).to eql activity_list_header
        end

        it 'assigns the classwork' do
          classwork = double('classwork')
          allow(@presenter).to receive(:classwork).and_return(classwork)
          do_request
          expect(assigns(:classwork)).to eql classwork
        end

        it 'assigns the attempt' do
          attempt = double('attempt')
          allow(@presenter).to receive(:attempt).and_return(attempt)
          do_request
          expect(assigns(:attempt)).to eql attempt
        end

        it 'assigns the attempt track' do
          attempt_track = double('attempt_track')
          allow(@presenter).to receive(:attempt_track).and_return(attempt_track)
          do_request
          expect(assigns(:attempt_track)).to eql attempt_track
        end

        it 'assigns the lesson header' do
          allow(@activity_presenter).to receive(:lesson_header).and_return('lesson header')
          do_request
          expect(assigns(:lesson_header)).to eq('lesson header')
        end
      end
    end
  end

  describe '#update' do
    before do
      populate_instructor_program_and_focus
      allow(@instructor).to receive(:update)
    end

    def do_request(params = { grading_style: 'spotcheck' })
      put :update, params: { program_id: @program.id, instructor: params }
    end

    it 'should set grading style' do
      expect(@instructor).to receive(:update).with(hash_including(grading_style: 'spotcheck'))
      allow(controller).to receive(:current_user).and_return(@instructor)
      do_request
    end

    it 'should redirect to assignments index' do
      do_request
      expect(response).to render_template 'update'
    end

    context 'when grading a multi-type activity with open ended questions' do
      it 'sets whether or not to show auto graded questions' do
        expect(@instructor).to receive(:update).with(hash_including(show_auto_graded_questions: 'true'))
        allow(controller).to receive(:current_user).and_return(@instructor)
        do_request(grading_style: 'spotcheck', show_auto_graded_questions: 'true')
      end
    end

    context 'when instructor is allowed to use AI grading suggestions' do
      it 'sets whether or not to enable AI grading suggestions' do
        expect(@instructor).to receive(:update).with(hash_including(enable_ai_grading_suggestions: 'true'))
        allow(controller).to receive(:current_user).and_return(@instructor)
        do_request(grading_style: 'student_by_student', enable_ai_grading_suggestions: 'true')
      end
    end
  end
end

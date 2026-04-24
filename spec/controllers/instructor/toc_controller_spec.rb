describe Instructor::TocController do
  include ApplicationHelper

  before do
    @user = build_stubbed(:instructor)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
    @program = build_stubbed(:program)
    allow(Program).to receive(:find_by_id).and_return(@program)
  end

  describe '#show' do
    def do_request(params={})
      get :show, params: { program_id: @program.id }.merge(params)
    end

    context 'before_action' do
      before(:each) do
        fake_login(@user)
      end

      context 'logged in user' do
        it_should_behave_like 'an action that requires a logged in instructor'
      end

      context 'contextual help' do
        it_should_behave_like 'an action that assigns contextual help'
      end
    end

    context 'assigns' do
      before do
        fake_login(@user)
        @presenter = double(InstructorTocPresenter , start_unit: 'start_unit')
        allow(InstructorTocPresenter).to receive(:new).and_return(@presenter)
      end

      it 'should assign presenter' do
        focus = double('Focus', course: nil, sections: [], students: [])
        allow(controller).to receive(:current_focus).and_return(focus)
        expect(InstructorTocPresenter).to receive(:new).with(
          @program,
          @user,
          focus,
          hash_including('program_id' => @program.id.to_s),
          anything
        ).and_return(@presenter)
        do_request
        expect(assigns(:presenter)).to eq(@presenter)
      end

      it 'should assign page title' do
        do_request
        expect(assigns(:page_title)).to eq('Activities')
      end

      it 'should set session ' do
        do_request
        expect(session[:activity_return]).to include('label' => 'Return to Activities')
      end

      it 'should assign sections ' do
        do_request
        expect(assigns(:sections)).to eq([])
      end

      it 'assigns path_options when param exists' do
        default_params = { display_lesson: 10, start_unit: 5, toc_location: 1000 }
        do_request(default_params)
        expect(assigns(:path_options)).to eq(display_lesson: '10', start_unit: '5', toc_location: '1000')
      end
    end

    describe 'activity_return url stored in the session' do
      before do
        fake_login(@user)
        @presenter = double(InstructorTocPresenter , start_unit: 'start_unit')
        allow(InstructorTocPresenter).to receive(:new).and_return(@presenter)
      end

      context 'when a non-blank display_lesson param is specified' do
        it 'stores an activity_return url that includes that display_lesson param' do
          display_lesson = 12345
          do_request(display_lesson: display_lesson)
          expected_url = instructor_toc_path(@program, display_lesson: display_lesson)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a blank display_lesson param is specified' do
        it 'stores an activity_return url that does not include a display_lesson param' do
          do_request(display_lesson: '')
          expected_url = instructor_toc_path(@program)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a non-blank start_unit param is specified' do
        it 'stores an activity_return url that includes that start_unit param' do
          start_unit = 12345
          do_request(start_unit: start_unit)
          expected_url = instructor_toc_path(@program, start_unit: start_unit)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a blank start_unit param is specified' do
        it 'stores an activity_return url that does not include a start_unit param' do
          do_request(start_unit: '')
          expected_url = instructor_toc_path(@program)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a non-blank toc_location param is specified' do
        it 'stores an activity_return url that includes that toc_location param' do
          toc_location = 12345
          do_request(toc_location: toc_location)
          expected_url = instructor_toc_path(@program, toc_location: toc_location)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end

      context 'when a blank toc_location param is specified' do
        it 'stores an activity_return url that does not include a toc_location param' do
          do_request(toc_location: '')
          expected_url = instructor_toc_path(@program)
          expect(session[:activity_return]['url']).to eq(expected_url)
        end
      end
    end
  end
end

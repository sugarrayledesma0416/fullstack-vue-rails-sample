describe Instructor::AssignmentsController do
  describe '#new' do
    def do_request
      get :new, params: { program_id: @program.id }
    end

    before do
      populate_instructor_program_and_focus(course_start_date: 1.week.ago.to_date, course_end_date: 1.week.from_now.to_date)
      allow(@focus).to receive(:has_atleast_one_actionable_section?).and_return(true)
      allow(@focus).to receive(:course_start_date).and_return(1.week.ago.to_date)
      allow(@focus).to receive(:course_end_date).and_return(1.week.from_now.to_date)
      allow(@focus).to receive(:type).and_return('section')
      allow(@focus).to receive(:class_days).and_return(%w[1 2 3])
      allow(@instructor).to receive(:all_sections_for_program).and_return([])

      @calendar_presenter = double(CalendarPresenter)
      @assignment_filter_presenter = double(AssignmentFilterPresenter)
      allow(CalendarPresenter).to receive(:build).and_return(@calendar_presenter)
      allow(AssignmentFilterPresenter).to receive(:new).and_return(@assignment_filter_presenter)
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'
    it_should_behave_like 'an action that assigns contextual help'

    it 'assigns assignment filter and calendar presenter' do
      do_request
      expect(assigns(:assignment_filter_presenter)).not_to be_nil
      expect(assigns(:calendar_presenter)).not_to be_nil
    end
  end

  describe '#index' do
    def do_request
      get :index, params: { program_id: @program.id }
    end

    before do
      populate_instructor_program_and_focus
      allow(@focus).to receive(:has_atleast_one_actionable_section?).and_return(true)
      allow(@focus).to receive(:type).and_return('section')
      allow(@focus).to receive(:class_days).and_return(%w[1 2 3])
      allow(@program).to receive(:lessons).and_return(@lessons)
      allow(@instructor).to receive(:all_sections_for_program).and_return([])
      @calendar_presenter = double(CalendarPresenter)
      allow(CalendarPresenter).to receive(:new).and_return(@calendar_presenter)
      allow(@calendar_presenter).to receive(:build_calendar)
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'

    it 'should create a one month calendar' do
      expect(@calendar_presenter).to receive(:build_calendar)
      do_request
    end
  end

  describe '#show_calendar' do
    def do_ajax_request(opts = {})
      # convert to hash as flash object don't respond to stringify_keys
      get :show_calendar, params: opts, flash: flash.to_h, xhr: true
    end

    before do
      @start_date = 1.month.ago.to_date
      @end_date = 3.months.from_now.to_date
      course = build_stubbed(:course, program: @program, start_date: @start_date, end_date: @end_date)

      populate_instructor_program_and_focus(course: course)
      allow(@focus).to receive(:course_start_date).and_return(@start_date)
      allow(@focus).to receive(:course_end_date).and_return(@end_date)
      allow(@focus).to receive(:type).and_return('section')
      allow(@focus).to receive(:class_days).and_return(%w[1 2 3])
      @year = Date.today.year
      @month = Date.today.month
      @year_month = "#{@year}-#{@month}"
      @calendar_settings = double(CalendarPresenter::CalendarSettings, sections: @focus.sections)
      allow(CalendarPresenter::CalendarSettings).to receive(:new).and_return(@calendar_settings)
      @calendar_presenter = double(CalendarPresenter)
      allow(CalendarPresenter).to receive(:build).and_return(@calendar_presenter)
      allow(controller).to receive(:render_to_string)
    end

    it 'should render the calendar' do
      expect(controller).to receive(:render).with(
        'instructor/calendar/_event_calendar',
        layout: false,
        locals: { calendar_presenter: @calendar_presenter }
      ).and_call_original
      get :show_calendar, params: { program_id: @program.id, year_month: @year_month }
    end

    it "doesn't render the calendar into a string" do
      expect(controller).not_to receive(:render_to_string)
      get :show_calendar, params: { program_id: @program.id, year_month: @year_month }
    end

    context 'when calendar is obtained through an Ajax call' do
      it 'renders a JSON response with the HTML as a content variable' do
        allow(controller).to receive(:render)
        expect(controller).to receive(:render_to_string).and_return('The calender HTML')
        json_rendering_params = { json: { message: nil, calendar_html: 'The calender HTML' } }
        expect(controller).to receive(:render).with(json_rendering_params)
        do_ajax_request(program_id: @program.id, year_month: @year_month, format: 'json')
      end

      it 'renders a JSON response with a message if flash[:notice] is present' do
        allow(controller).to receive(:render)
        flash[:notice] = 'Something has been created.'
        json_rendering_params = { json: { message: 'Something has been created.', calendar_html: nil } }
        expect(controller).to receive(:render).with(json_rendering_params)
        do_ajax_request(program_id: @program.id, year_month: @year_month, format: 'json')
      end
    end
  end

  describe '#show_more' do
    before do
      populate_instructor_program_and_focus(course_start_date: 1.week.ago.to_date, course_end_date: 1.week.from_now.to_date)
      allow(@focus).to receive(:has_atleast_one_actionable_section?).and_return(true)
      allow(@focus).to receive(:course_start_date).and_return(1.week.ago.to_date)
      allow(@focus).to receive(:course_end_date).and_return(1.week.from_now.to_date)
      allow(@focus).to receive(:type).and_return('section')
      allow(@focus).to receive(:class_days).and_return(%w[1 2 3])

      @filter = build_stubbed(:assignment_filter)
      @assignment_filter_presenter = double(AssignmentFilterPresenter)
      allow(@assignment_filter_presenter).to receive(:filter).and_return(@filter)
      allow(@assignment_filter_presenter).to receive(:grouped_unassigned_activities).and_return([])
      allow(AssignmentFilterPresenter).to receive(:new).and_return(@assignment_filter_presenter)
    end

    def do_request(opts = {})
      get :show_more, params: { program_id: @program.id }.merge(opts), xhr: true
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'

    it 'renders the unassigned activities list' do
      allow(controller).to receive(:render)
      expect(controller).to receive(:render).with(partial: 'unassigned_activities', layout: false, locals: { presenter: @assignment_filter_presenter })
      do_request
    end
  end
end

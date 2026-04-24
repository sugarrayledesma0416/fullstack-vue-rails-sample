describe Instructor::OldCourseYearsController do
  before do
    instructor = build_stubbed(:instructor)
    allow(instructor).to receive(:has_current_access_to?).and_return(true)
    fake_login(instructor)
  end

  describe '#index' do
    def do_request
      get :index, params: { program_id: @program.id }
    end

    before do
      @program = build_stubbed(:program)
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    context 'with a logged in user' do
      before do
        @instructor = build_stubbed(:instructor)
        allow(@instructor).to receive(:has_current_access_to?).and_return(true)
        fake_login(@instructor)
        allow(Program).to receive(:find_by_id).with(@program.id.to_s).and_return(@program)
      end

      it 'assigns a list of the past 5 years back to 2012 (the beginning of maestro3)' do
        Timecop.travel(2014, 3, 4) do
          do_request
          expect(assigns(:years)).to eq([2014, 2013, 2012, 2011])
        end
      end
    end
  end

  describe '#show' do
    def do_request
      get :show, params: { program_id: @program.id, id: 2012 }
    end

    before do
      @program = build_stubbed(:program)
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    context 'with a logged in user' do
      before do
        @instructor = build_stubbed(:instructor)
        allow(@instructor).to receive(:has_current_access_to?).and_return(true)
        fake_login(@instructor)
        allow(Program).to receive(:find_by_id).with(@program.id.to_s).and_return(@program)
      end

      it "assigns the old courses and sections for the instructor's program for the current year" do
        expect(@instructor).to receive(:closed_courses_by_program_and_year_with_owned_sections).with(@program, '2012').and_return(%w[foo bar])
        do_request
        expect(assigns(:courses_and_sections)).to eq(%w[foo bar])
      end
    end
  end
end

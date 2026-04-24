shared_examples_for "an action that assigns program and focus" do
  it "should set the focus level" do
    do_request
    expect(assigns(:current_focus)).to eql @focus
  end

  it "should find and assign a program" do
    expect(Program).to receive(:find_by_id).with(@program.id.to_s).and_return(@program)
    do_request
    expect(assigns(:program)).not_to be_nil
    expect(assigns(:program)).to eql @program
  end

  it "should create a focus for the current user and program" do
    expect(Focus).to receive(:new).with( @user, @program, anything()).and_return(@focus)
    do_request
  end

  it "should find and assign course from the focus" do
    expect(@focus).to receive(:course).and_return(@course)
    do_request
    expect(assigns(:course)).not_to be_nil
    expect(assigns(:course)).to eql @course
  end

  it "should find and assign sections from the focus" do
    expect(@focus).to receive(:sections).and_return(@sections)
    do_request
    expect(assigns(:sections)).not_to be_nil
    expect(assigns(:sections)).to eql @sections
  end

  it "should find and assign students from the focus" do
    expect(@focus).to receive(:students).and_return(@students)
    do_request
    expect(assigns(:students)).not_to be_nil
    expect(assigns(:students)).to eql @students
  end
end

shared_examples_for "a view that displays a focus menu" do

  before(:each) do
    assign(:program, build_stubbed(:program))
  end

  it 'renders the focus partial' do
    do_render
    expect(rendered).to render_template(:partial => 'instructor/focus/_show')
  end
end

def populate_instructor_program_and_focus(params = {})
  @instructor = params[:instructor] || create(:instructor)
  allow(@instructor).to receive(:has_current_access_to?).and_return(true)
  fake_login(@instructor)

  @timeframe = params[:timeframe] || 'valid_setting'
  allow(@instructor).to receive(:setting).and_return(@timeframe)

  @program = params[:program] || create(:program, maestro_version: 3)

  @course = params[:course] || create(:course, program: @program)
  allow(@course).to receive(:available_components).and_return(['Practice'])
  allow(@instructor).to receive(:open_courses_for_program).and_return([@course])

  @students = []
  @sections = params[:sections] || []
  @sort = {:column => 'Name', :direction => 'desc', :category_id => ''}

  @focus = instance_double(
    Focus,
    course: @course,
    sections: @sections,
    section: @sections.first,
    :present? => true,
    students: @students,
    course_start_date: params[:course_start_date],
    course_end_date: params[:course_end_date]
  ).as_null_object
  allow(Focus).to receive(:new).and_return(@focus)
end

shared_examples_for "an action that assigns program and course, sections, and students from focus" do
  it "should set the focus level" do
    do_request
    expect(assigns(:current_focus)).to eql @focus
  end

  it "should find and assign a program" do
    expect(Program).to receive(:find_by_id).with(@program.id.to_s).and_return(@program)
    do_request
    expect(assigns(:program)).not_to be_nil
    expect(assigns(:program)).to eql @program
  end

  it "should create a focus for the current user and program" do
    expect(Focus).to receive(:new).with( @instructor, @program, anything()).and_return(@focus)
    do_request
  end

  it "should find and assign course from the focus" do
    expect(@focus).to receive(:course).and_return(@course)
    do_request
    expect(assigns(:course)).not_to be_nil
    expect(assigns(:course)).to eql @course
  end

  it "should find and assign sections from the focus" do
    expect(@focus).to receive(:sections).and_return(@sections)
    do_request
    expect(assigns(:sections)).not_to be_nil
    expect(assigns(:sections)).to eql @sections
  end

  it "should find and assign students from the focus" do
    expect(@focus).to receive(:students).and_return(@students)
    do_request
    expect(assigns(:students)).not_to be_nil
    expect(assigns(:students)).to eql @students
  end
end

shared_examples_for 'an action that creates and assigns focus' do
  it 'initalizes and assign a new focus object with the specified program' do
    @instructor ||= create(:instructor)
    allow(@controller).to receive(:current_user).and_return(@instructor)

    @prkgram ||= create(:program, maestro_version: 3)

    @course ||= create(:course, program: @program)
    allow(@instructor).to receive(:open_courses_for_program).and_return([@course])

    @focus ||= double(Focus, course: @course, sections: [], students: [])
    expect(Focus).to receive(:new).with(@instructor, @program, anything()).and_return(@focus)

    do_request

    expect(assigns(:current_focus)).to eql @focus
  end
end

shared_examples_for 'an action that assigns variables needed for the focus menu' do
  context 'when the user is viewing a section in a closed course,' do
    it 'should add the closed section information to courses and sections' do
      skip 'klm'
      user = build_stubbed(:instructor)
      allow(user).to receive(:has_current_access_to?).and_return(true)
      allow(@controller).to receive(:current_user).and_return(user)

      allow(user).to receive(:setting).and_return('valid_setting')

      @program ||= build_stubbed(:program, :maestro_version => 3)
      allow(Program).to receive(:find_by_id).and_return(@program)

      @closed_course_section = build_stubbed(:section)
      allow(Section).to receive(:find).with(@closed_course_section.id).and_return(@closed_course_section)

      session[:closed_course_section] = {:section_id => @closed_course_section.id}
      allow(session).to receive(:has_key?).with(:closed_course_section).and_return(true)

      do_request

      expect(assigns(:courses_and_sections)).to eql([[@closed_course_section.name, "Section,#{@closed_course_section.id}"]])
    end
  end
end

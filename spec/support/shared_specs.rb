# allow debugging based on text written to an IO object
class IO
  alias :write_orig :write
  def write(*args)
    begin
      if args[0] =~ /ignoring attempt to close/
        puts caller(0).grep(/html\.erb/).join("\n")
      end
    rescue ArgumentError => e
      raise(e) unless e.message == 'invalid byte sequence in UTF-8'
    end
    write_orig(*args)
  end
end

def it_should_assign_section_header(&block)

  context "section header" do
    before(:each) do
      @user = build_stubbed(:student)
      allow(@user).to receive(:has_current_access_to?).and_return(true)
      @program = build_stubbed(:program)
      allow(controller).to receive(:current_program).and_return(@program)
      @course = build_stubbed(:course, :name => 'section_header_test_course_name')
      @section = build_stubbed(:section, :course => @course)
      allow(@section).to receive(:course_name).and_return(@course.name)
      allow(@section).to receive(:closed?).and_return(false)
      allow(Section).to receive(:find_by_id).and_return(@section)

      @lesson_1 = build_stubbed(:lesson_with_toc_entries)
      current_assignments = double('AssignmentSet')
      @classwork = double(Classwork, :section => @section, :user => @user).as_null_object
      allow(Classwork).to receive(:new).and_return(@classwork)
      allow(current_assignments).to receive(:lessons_for_next_assignment_day).and_return([@lesson_1])
      fake_login(@user)
      allow(controller).to receive(:current_section).and_return( @section )
      allow(@user).to receive(:current_section_in_program).and_return( @section )
    end

    it "assigns the course name" do
      instance_eval(&block)
      expect(assigns[:section_header][:course_name]).to eql('section_header_test_course_name')
    end

    it "assigns closed section status based on section's closed status" do
      instance_eval(&block)
      expect(assigns[:section_header][:closed]).to eql(false)
    end
  end
end

def it_should_display_a_section_header(&block)

  context "with a valid section id" do

    before(:each) do
      @user = build_stubbed(:student)
      @program = build_stubbed(:program)
      allow(controller).to receive(:current_program).and_return(@program)
      @course = build_stubbed(:course, :name => 'section_header_test_course_name')
      @section = build_stubbed(:section, :course => @course)
      allow(Section).to receive(:find_by_id).and_return(@section)
      fake_login(@user)
    end

    context "when the user is active" do
      before(:each) do
        allow(@user).to receive(:closed?).and_return(false)
        instance_eval(&block)
      end

      it "should display the course name" do
       # puts response.body
        expect(response).to have_tag('h1', :text => /section_header_test_course_name/)
      end

      it "should not display the course as closed" do
        expect(response).not_to have_tag('h1', :text => /closed/i)
      end
    end

    context "where the user is closed" do
      before(:each) do
        allow(@user).to receive(:closed?).and_return(true)
        instance_eval(&block)
        fake_login(@user)
      end

      it "should display the course name" do
        expect(response).to have_tag('h1', :text => /section_header_test_course_name Name/)
      end

      it "should display the course as closed" do
        expect(response).to have_tag('h1', :text => /closed/i)
      end
    end

  end

end

# A view test helper which verifies the presence of input tags and labels.
def it_should_have_a_labeled_field(model, field_name)
  human_readable = field_name.gsub("_", " ")
  it "should have a #{human_readable} field" do
    expect(response).to have_tag("input[id='#{model}_#{field_name}']")
  end

  it "should have a label for the #{human_readable} field" do
    expect(response).to have_tag("label[for='#{model}_#{field_name}']")
  end
end

def it_should_have_a_labeled_select_box(model, field_name)
  human_readable = field_name.gsub("_", " ")
  it "should have a #{human_readable} field" do
    expect(response).to have_tag("select[id='#{model}_#{field_name}']")
  end

  it "should have a label for the #{human_readable} field" do
    expect(response).to have_tag("label[for='#{model}_#{field_name}']")
  end
end

# Verifies that a controller action requires that a user is logged in.
# use it like:
#
#    it_should_require_a_logged_in_user { get "edit" }
#
def it_should_require_a_logged_in_user(&block)
  it 'calls the require_user filter' do
    expect(controller).to receive(:require_user).and_raise(StandardError)
    expect { instance_eval(&block) }.to raise_error(StandardError)
  end
end

shared_examples_for "an action that requires category info in session" do
  it 'verifies presence of category info in session' do
    session[:category_attributes] = nil
    do_request
    expect(response).to render_template 'expired'
  end

  it 'verifies presence of category info in session for a specific course' do
    session[:category_attributes][course.id] = nil
    do_request
    expect(response).to render_template 'expired'
  end
end

shared_examples_for "an ajax action that requires category info in session" do
  context "when the session category attributes is empty" do
    before do
      session[:category_attributes] = nil
    end

    it "sets a flash notice" do
      do_request
      expect(flash[:notice]).to eql "Course wizard has been completed or interrupted."
    end
  end
end

shared_examples_for "an action that requires a logged in user" do
  it 'calls the require_user filter' do
    expect(@controller).to receive(:require_user).and_raise(StandardError)
    expect { do_request }.to raise_error(StandardError)
  end
end

shared_examples_for "an action that requires a logged in instructor or grader" do

  it 'calls the require_instructor_or_grader filter' do
    expect(@controller).to receive(:require_instructor_or_grader).and_raise(StandardError)
    expect { do_request }.to raise_error(StandardError)
  end
end

shared_examples_for "an action that requires a logged in student" do
  it "calls the require_student filter" do
    expect(@controller).to receive(:require_student).and_raise(StandardError)
    expect { do_request }.to raise_error(StandardError)
  end
end

shared_examples_for "an action that requires a logged in instructor" do
  it "calls the require_instructor filter" do
    expect(@controller).to receive(:require_instructor).and_raise(StandardError)
    expect { do_request }.to raise_error(StandardError)
  end
end

shared_examples_for 'an action that requires a logged in institution admin' do
  it 'calls the require_institution_admin filter' do
    expect(@controller).to receive(:require_institution_admin).and_raise(StandardError)
    expect { do_request }.to raise_error(StandardError)
  end
end

def it_should_require_a_student_or_instructor(&block)
  it "should require a student" do
    fake_login(build_stubbed(:student))
    instance_eval(&block)
    if response.redirect?
      expect(response.redirected_to).not_to eq(home_path)
    else
      expect(response).to be_successful
    end
  end

  it "should require an instructor" do
    fake_login(build_stubbed(:instructor))
    instance_eval(&block)
    if response.redirect?
      expect(response.redirected_to).not_to eq(home_path)
    else
      expect(response).to be_successful
    end
  end

  it "should redirect an editor" do
    fake_login(build_stubbed(:editor))
    instance_eval(&block)
    if response.redirect?
      expect(response.redirected_to).to eq(home_path)
    else
      expect(response).to be_failure
    end
  end

  it "should redirect a grader" do
    fake_login(build_stubbed(:grader))
    instance_eval(&block)
    if response.redirect?
      expect(response.redirected_to).to eq(home_path)
    else
      expect(response).to be_failure
    end
  end
end



shared_examples_for "an action that blocks maestro2 programs" do
  context "when passed maestro 2 parameters" do
    it "should return a 404 error" do
      program = create(:m2_program)
      course  = create(:course, :program => program)
      section = create(:section, :course => course)

      user = build_stubbed(:student)
      allow(user).to receive(:has_current_access_to?).and_return(true)

      fake_login(user)

      expect{ do_request_with_section(section) }.to raise_error(ActionController::RoutingError)
    end
  end
end

shared_examples_for "a page that requires program access" do
  # TODO: Replace usage of this shared spec with "an action that requires program access"
  #       defined below, to eliminate the need for as much stubbing and the need to define a separate
  #       do_request_with_section method in controller specs just to run this one test
  context "when the user does not have current program access" do
    it "sets a flash error and redirects to the UA access problems page" do
      program = build_stubbed(:program)
      allow(Program).to receive(:find_by_id).and_return(program)
      allow(controller).to receive(:current_program).and_return(program)

      course  = build_stubbed(:course, :program => program)
      allow(course).to receive(:program).and_return(program)

      section = build_stubbed(:section, :course => course)
      allow(section).to receive(:course).and_return(course)
      allow(section).to receive(:program).and_return(program)

      allow(Section).to receive(:find_by_id).and_return(section)

      user = build_stubbed(:student)
      expect(user).to receive(:has_current_access_to?).with(program).and_return(false)

      fake_login(user)

      do_request_with_section(section)

      expect(response.redirect_url).to eql "#{UA_URL}/access_problem/#{program.id}"
    end
  end
end

shared_examples_for "an action that requires program access" do
  context "when the user does not have current program access" do
    it "sets a flash error and redirects to the UA access problems page" do
      program = build_stubbed(:program)
      allow(controller).to receive(:current_program).and_return(program)

      section = build_stubbed(:section_with_course)
      allow(section).to receive(:program).and_return(program)
      allow(controller).to receive(:current_section).and_return(section)

      user = build_stubbed(:student)
      expect(user).to receive(:has_current_access_to?).with(program).and_return(false)
      allow(user).to receive(:current_section_in_program) { nil }

      fake_login(user)
      do_request

      expect(response.redirect_url).to eql "#{UA_URL}/access_problem/#{program.id}"
    end
  end
end

# Verifies that a controller action requires that a user is not logged in.
# use it like:
#
#    it_should_require_a_logged_out_user { get "new" }
#
def it_should_require_a_logged_out_user(&block)
  it "should succeed when not logged in" do
    instance_eval(&block)
    expect(response).to be_successful
  end

  context "when logged in" do
    before(:each) do
      fake_login
      instance_eval(&block)
    end

    it "should fail" do
      expect(response).not_to be_successful
    end

    it "should redirect to the home page" do
      expect(response).to redirect_to("/home")
    end

    it "should set a flash notice" do
      expect(response.flash[:notice]).to include("logged out")
    end
  end
end

def fake_context(args = {})
  fake_login(args[:user]) if args[:user]
  allow(controller).to receive(:current_section).and_return(args[:section])if args[:section]
end


def fake_login(user = nil)
  user = build_stubbed(:student) if user.nil?
  persistent_session = build_stubbed(:persistent_session)
  allow(persistent_session).to receive(:touch)
  allow(persistent_session).to receive(:valid?).and_return(true)
  allow(controller).to receive(:persistent_session).and_return(persistent_session)
  allow(controller).to receive(:current_user).and_return(user)
  allow(controller).to receive(:current_user).and_return(user)
end

def it_should_have_help
  it "should have help" do
    expect(controller).to have_help
  end
end

def create_student_answers(student)
  allow(@question).to receive(:label).and_return('question_01')
  assigns[:question] = @question
  results = double(MaestroActivityEngine::ActivityContent::Results)
  allow(results).to receive(:response).and_return('Lorem ipsum dolor sit amet')
  attempt = build_stubbed(:attempt)
  allow(attempt).to receive(:results).and_return(results)
  student_answers = {student.id.to_s => attempt}
  assigns[:student_answers] = student_answers
end

shared_examples_for "an action that assigns menu location" do
  it "should assign the correct information for the navigation menu" do
    do_request
    expect(assigns[:menu_location]).to eql @menu_location
  end
end

shared_examples_for "an action that denies access to clients with external ip addresses" do
  it "calls the require_local_client filter" do
    expect(@controller).to receive(:require_local_client).and_raise(StandardError.new('local ip required'))
    expect { do_request }.to raise_error(StandardError, /local ip required/)
  end
end


shared_examples_for "a ua service action that denies access to clients with external ip addresses" do
  it "calls the require_local_client filter" do
    expected_error = StandardError.new('local ip required')
    expect(@controller).to receive(:require_local_client).and_raise(expected_error)
    expect(VHLMonitor).to receive(:notify).with(expected_error)
    do_request
  end
end

shared_examples_for "an action that requires assessment component access" do
  it "calls the assessment component filter" do
    program_settings = double(ProgramSettings)
    allow(program_settings).to receive(:has_assessment?).and_return false
    expect(ProgramSettings).to receive(:new).with(@program).and_return(program_settings)
    do_request
    expect(response).to redirect_to @expected_redirect
  end
end

shared_examples_for "an action that requires pronto availability" do
  it "redirects when settings for the program do not contain pronto" do
    program_settings = double(ProgramSettings)
    allow(program_settings).to receive(:has_pronto?).and_return false
    expect(ProgramSettings).to receive(:new).with(@program).and_return(program_settings)
    do_request
    expect(response).to redirect_to @expected_redirect
  end

  it "redirects when there are no program_settings" do
    allow(ProgramSettings).to receive(:new).and_return(nil)
    do_request
    expect(response).to redirect_to @expected_redirect
  end
end

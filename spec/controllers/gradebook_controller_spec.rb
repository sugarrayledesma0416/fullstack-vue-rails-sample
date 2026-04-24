require 'pry'

describe GradebookController do
  include GradebookHelper
  include ApplicationHelper

  before do
    session[:last_gradebook_route] = {}
  end

  def set_up_program_and_focus(params = {})
    @user = build_stubbed(:instructor)
    fake_login(@user)

    @program = build_stubbed(:program, maestro_version: 3)
    allow(Program).to receive(:find_by_id).and_return(@program)

    @course = build_stubbed(:course, program: @program)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
    allow(@user).to receive(:open_courses_for_program).and_return([@course])

    @students = params[:students] || []
    @sections = params[:sections] || []

    @sort = { column: 'Name', direction: 'desc', category_id: '' }

    @category = build_stubbed(:category, id: 123)
    allow(Category).to receive(:find_by_id).and_return(@category)

    @focus = double(Focus, course: @course, sections: @sections, students: @students, type: 'foo', course_school_id: @course.school_id, course_id: nil)
    allow(Focus).to receive(:new).and_return(@focus)
  end

  shared_examples 'an action that requires a course' do
    it 'should redirect the user if they do not have a course' do
      allow(@focus).to receive(:course).and_return(nil)
      do_request
      expect(response).to redirect_to "/gradebook/#{@program.id}"
    end
  end

  shared_examples 'an action that assigns grade display style' do
    it 'should get the grade display style setting from the user' do
      allow(@user).to receive(:setting).with(Setting::Gradebook::CategoryView).and_return('lessons')
      expect(@user).to receive(:setting).with(Setting::Gradebook::GradeDisplayStyle).and_return('valid_setting')
      do_request
    end

    it 'should assign grade display style setting' do
      do_request
      expect(assigns(:grade_display_style)).to eq('percent')
    end
  end

  shared_examples 'a gradebook when there are no students' do
    it 'should check your focus type' do
      @students = []
      expect(@focus).to receive(:type)
      do_request
    end

    it 'should flash a notice' do
      @students = []
      do_request
      expect(flash[:notice]).to include 'students'
    end
  end
end

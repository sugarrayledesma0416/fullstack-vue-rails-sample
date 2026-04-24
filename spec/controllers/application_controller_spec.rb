describe ApplicationController do
  let(:ssjr_program) do
    instance_double(Program, supersite_junior?: true)
  end

  let(:nonjr_program) do
    instance_double(Program, supersite_junior?: false)
  end

  let(:student) do
    instance_double(User, student?: true, instructor?: false)
  end

  let(:instructor) do
    instance_double(User, student?: false, instructor?: true)
  end

  describe '#vista_online_learning?' do
    let(:program) { build_stubbed(:program) }
    let(:vol_program) { build_stubbed(:vol_program) }

    it 'returns true if the current program is vista_online_learning' do
      allow(controller).to receive(:current_program).and_return(vol_program)
      expect(controller.helpers.vista_online_learning?).to be true
    end

    it 'returns false if the current program is not vista_online learning' do
      allow(controller).to receive(:current_program).and_return(program)
      expect(controller.helpers.vista_online_learning?).to be false
    end

    it 'returns false if there is no current program' do
      allow(controller).to receive(:current_program).and_return(nil)
      expect(controller.helpers.vista_online_learning?).to be false
    end
  end

  describe '#supersite_junior?' do
    context 'when no url parameters are specified' do
      it 'is false when current_program is nil' do
        allow(controller).to receive(:current_program).and_return(nil)

        expect(controller).not_to be_supersite_junior
      end

      it 'is false if current_program is not a supersite junior program' do
        allow(controller).to receive(:current_program).and_return(nonjr_program)

        expect(controller).not_to be_supersite_junior
      end

      it 'is true if current_program is a supersite junior program' do
        allow(controller).to receive(:current_program).and_return(ssjr_program)

        expect(controller).to be_supersite_junior
      end
    end

    context 'when current_program is not a supersite junior program' do
      before do
        allow(controller).to receive(:current_program).and_return(nonjr_program)
      end

      it 'is false if there is no preview_theme param' do
        expect(controller).not_to be_supersite_junior
      end

      it 'is false if the preview_theme param is not set to "junior"' do
        controller.params[:preview_theme] = 'senior'

        expect(controller).not_to be_supersite_junior
      end

      it 'is true if the preview_theme param is set to "junior"' do
        controller.params[:preview_theme] = 'junior'

        expect(controller).to be_supersite_junior
      end
    end
  end

  describe 'ssjr_instructor?' do
    it 'is false if current_program is not a supersite junior program' do
      allow(controller).to receive(:current_program).and_return(nonjr_program)

      expect(controller).not_to be_ssjr_instructor
    end

    context 'when current_program is a supersite junior program' do
      before do
        allow(controller).to receive(:current_program).and_return(ssjr_program)
      end

      it 'is false if user is not an instructor' do
        allow(controller).to receive(:current_user).and_return(student)

        expect(controller).not_to be_ssjr_instructor
      end

      it 'is true if user is an instructor' do
        allow(controller).to receive(:current_user).and_return(instructor)

        expect(controller).to be_ssjr_instructor
      end
    end
  end

  describe 'ssjr_student?' do
    it 'is false if current_program is not a supersite junior program' do
      allow(controller).to receive(:current_program).and_return(nonjr_program)

      expect(controller).not_to be_ssjr_student
    end

    context 'when current_program is a supersite junior program' do
      before do
        allow(controller).to receive(:current_program).and_return(ssjr_program)
      end

      it 'is false if user is not a student' do
        allow(controller).to receive(:current_user).and_return(instructor)

        expect(controller).not_to be_ssjr_student
      end

      it 'is true if user is a student' do
        allow(controller).to receive(:current_user).and_return(student)

        expect(controller).to be_ssjr_student
      end
    end
  end
end

describe ApplicationController, 'require_user filter' do
  shared_examples_for 'an action that handles user redirection' do
    before do
      allow(CASClient::Frameworks::Rails::Filter).to receive(:filter).and_return(true)
    end

    it 'stores the location' do
      expect(@controller).to receive(:store_location)
      get :index
    end

    it 'sets the flash' do
      get :index
      expect(flash[:notice]).to eq(LOGIN_REQUIRED_MESSAGE)
    end

    it 'redirects to the ua login' do
      get :index
      expect(response).to redirect_to(ua_home_path)
    end
  end

  shared_examples_for 'an action that allows the user to access it with a valid session' do
    it 'redirects to the ua login when session is invalid' do
      allow(persistent_session).to receive(:valid?).and_return(false)
      expect(persistent_session).to receive(:delete)
      get :index
      expect(response).to redirect_to("#{UA_URL}/logout")
    end

    it 'returns true when the session is valid' do
      allow(persistent_session).to receive(:valid?).and_return(true)
      get :index
      expect(response).to be_successful
    end

    it 'updates the sessions audit' do
      allow(persistent_session).to receive(:valid?).and_return(true)
      expect(persistent_session).to receive(:lazy_touch)
      get :index
    end
  end

  context 'when not using the cartridge viewable module' do
    controller do
      before_action :require_user

      def index
        render plain: 'empty method'
      end
    end

    context 'current_user is set' do
      let(:user) { build_stubbed(:user) }
      let(:session_id) { 'session_id' }
      let(:persistent_session) { build_stubbed(:persistent_session) }

      before do
        allow(persistent_session).to receive(:lazy_touch)
        allow(Session).to receive(:where).and_return([persistent_session])
        allow(@controller).to receive(:current_user).and_return(user)
        session[:session_id] = session_id
      end

      context 'when a user is not a cartridge user' do
        before do
          allow(user).to receive(:cartridge?).and_return(false)
        end

        it_behaves_like 'an action that allows the user to access it with a valid session'
      end

      context 'when a user is a cartridge user' do
        before do
          allow(user).to receive(:cartridge?).and_return(true)
          allow(CASClient::Frameworks::Rails::Filter).to receive(:filter).and_return(true)
        end

        it 'redirects to the 403 error page' do
          get :index
          expect(response).to redirect_to('/403')
        end
      end
    end

    context 'when there is no current user' do
      context 'when the current user is not set by the cas_user key' do
        it_behaves_like 'an action that handles user redirection'
      end
    end
  end

  context 'when using the cartridge viewable module' do
    controller do
      include CartridgeViewable
      before_action :require_user

      def index
        render plain: 'empty method'
      end
    end

    context 'current_user is set' do
      let(:user) { build_stubbed(:user) }
      let(:session_id) { 'session_id' }
      let(:persistent_session) { build_stubbed(:persistent_session) }

      before do
        allow(persistent_session).to receive(:lazy_touch)
        allow(Session).to receive(:where).and_return([persistent_session])
        allow(@controller).to receive(:current_user).and_return(user)
        session[:session_id] = session_id
      end

      context 'when a user is not a cartridge user' do
        before do
          allow(user).to receive(:cartridge?).and_return(false)
        end

        it_behaves_like 'an action that allows the user to access it with a valid session'
      end

      context 'when a user is a cartridge user' do
        before do
          allow(user).to receive(:cartridge?).and_return(true)
        end

        it_behaves_like 'an action that allows the user to access it with a valid session'
      end
    end

    context 'when there is no current user' do
      context 'when the current user is not set by the cas_user key' do
        it_behaves_like 'an action that handles user redirection'
      end
    end
  end
end

describe ApplicationController, 'require_instructor filter' do
  # Don't name RequireInstructor controller, since we have a real controller named that.
  controller do
    before_action :require_instructor

    def index
      render plain: 'empty method'
    end
  end

  context 'when current_user is a instructor' do
    let(:user) { build_stubbed(:instructor) }

    it 'returns true' do
      allow(@controller).to receive(:current_user).and_return(user)
      get :index
      expect(response).to be_successful
    end
  end

  context 'when current_user is not an instructor' do
    let(:user) { build_stubbed(:student) }

    before do
      allow(@controller).to receive(:current_user).and_return(user)
    end

    context 'when the request is not ajax' do
      it 'sets the flash' do
        get :index
        expect(flash[:error]).to eq('You must have Instructor access to view the requested page.')
      end

      it 'redirects to the ua login' do
        get :index
        expect(response).to redirect_to(ua_home_path)
      end
    end

    context 'when the request is ajax' do
      it 'returns 401 status and approirate error message' do
        get :index, xhr: true
        expect(response.body).to include('User must have Instructor access')
        expect(response.status).to eq(401)
      end
    end
  end
end

describe ApplicationController, 'warn_insufficient_course_access filter' do
  controller do
    before_action :warn_insufficient_course_access, unless: :has_grace_period?

    def index
      render plain: 'empty method'
    end
  end

  context 'when current_user is a instructor' do
    let(:user) { build_stubbed(:instructor) }

    before do
      allow(@controller).to receive(:current_user).and_return(user)
    end

    it 'flash warning should not be set' do
      get :index
      expect(flash[:warning]).to be_nil
    end
  end

  context 'when current_user is a student' do
    let(:user) { build_stubbed(:student) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:has_grace_period?).and_return(false)
    end

    context 'when current section is section zero ' do
      it 'flash warning should not be set' do
        allow(controller).to receive(:current_section).and_return(Section.section_zero)
        get :index
        expect(flash[:warning]).to be_nil
      end
    end

    context 'when current section is not section zero ' do
      let(:section) { build_stubbed(:section) }
      before do
        allow(controller).to receive(:current_section).and_return(section)
      end

      context 'when a enrollment has sufficient access' do
        before do
          allow(user).to receive(:sufficient_access_for_course?).with(section).and_return(true)
        end

        it 'flash warning should not be set' do
          get :index
          expect(flash[:warning]).to be_nil
        end
      end

      context 'when a enrollment does not have sufficient access' do
        before do
          allow(user).to receive(:sufficient_access_for_course?).with(section).and_return(false)
        end

        it 'sets flash warning' do
          get :index
          expect(flash[:warning]).to eq("You don't have all the required access to complete this course.")
        end

        context 'and student has grace period access' do
          it 'does not set a flash warning' do
            allow(controller).to receive(:has_grace_period?).and_return(true)
            get :index
            expect(flash[:warning]).to be_nil
          end
        end
      end
    end
  end
end

describe ApplicationController, 'require_program_access filter' do
  controller do
    before_action :require_program_access

    def index
      render plain: 'empty method'
    end

    def show
      render plain: 'fake render'
    end
  end

  context 'when current_user is a student' do
    let(:user) { build_stubbed(:student) }

    before do
      allow(@controller).to receive(:current_user).and_return(user)
    end

    context 'when section is archived' do
      it 'redirects to ua home' do
        section = double(Section, exists?: true)
        section_scope = double('scope', where: section)
        allow(Section).to receive(:unscoped) { section_scope }
        get :index
        expect(response).to redirect_to(ua_home_path)
      end
    end

    context 'when section is not archived' do
      before do
        section = double(Section, exists?: false)
        section_scope = double('scope', where: section)
        allow(Section).to receive(:unscoped) { section_scope }
      end

      context 'when no program id parameter is specified' do
        it 'raises a routing error' do
          expect { get :index }.to raise_error ActionController::RoutingError
        end
      end

      context 'when a program id parameter is specified' do
        let(:program) { build_stubbed(:program) }

        before do
          allow(Program).to receive(:find_by_id).and_return(program)
        end

        context 'when student has access to the specified program' do
          it 'returns true' do
            expect(user).to receive(:has_current_access_to?).with(program).and_return(true)
            get :index, params: { program_id: program.id }
            expect(response).to be_successful
          end
        end

        context 'when student does not have access to the specified program' do
          it 'redirects to the ua program access page' do
            expect(user).to receive(:has_current_access_to?).with(program).and_return(false)
            get :index, params: { program_id: program.id }
            expect(response).to redirect_to "#{UA_URL}/access_problem/#{program.id}"
          end
        end
      end
    end
  end

  context 'when current_user is a instructor' do
    let(:user) { build_stubbed(:instructor) }

    before do
      allow(@controller).to receive(:current_user).and_return(user)
    end

    context 'when no program id parameter is specified' do
      it 'returns true without checking if user has program access' do
        expect(user).not_to receive(:has_current_access_to?)
        get :index
        expect(response).to be_successful
      end
    end

    context 'when a program id parameter is specified' do
      let(:program) { build_stubbed(:program) }

      before do
        allow(Program).to receive(:find_by_id).and_return(program)
      end

      context 'when instructor has access to the specified program' do
        it 'returns true' do
          expect(user).to receive(:has_current_access_to?).with(program).and_return(true)
          get :index, params: { program_id: program.id }
          expect(response).to be_successful
        end
      end

      context 'when instructor does not have access to the specified program' do
        it 'redirects to the ua access problem page' do
          expect(user).to receive(:has_current_access_to?).with(program).and_return(false)
          get :index, params: { program_id: program.id }
          expect(response).to redirect_to "#{UA_URL}/access_problem/#{program.id}"
        end
      end
    end
  end

  context 'when current_user is a common cartridge instructor ' do
    let(:user) { build_stubbed(:cartridge_instructor) }
    let(:program) { build_stubbed(:program) }
    let(:activity) { build_stubbed(:activity) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(user).to receive(:cartridge?).and_return(true)
    end

    context 'when an instructor does not have access to a program' do
      before do
        allow(Program).to receive(:find_by_id).and_return(program)
        allow(user).to receive(:has_current_access_to?).with(program).and_return(false)
      end

      it 'redirects to the activity access denied page' do
        get :show, params: { id: activity.id, program_id: program.id }
        expect(response).to redirect_to cartridge_access_denied_path(activity.id)
      end

      it 'sends the cartridge? message' do
        get :show, params: { id: activity.id, program_id: program.id }
        expect(user).to have_received(:cartridge?)
      end
    end

    context 'when an instructor does have access to a program' do
      before do
        allow(Program).to receive(:find_by_id).and_return(program)
        allow(user).to receive(:has_current_access_to?).with(program).and_return(true)
      end

      it 'returns a successful status' do
        get :show, params: { id: activity.id, program_id: program.id }
        expect(response).to be_successful
      end

      it 'displays the activity' do
        get :show, params: { id: activity.id, program_id: program.id }
        expect(response.body).to eq('fake render')
      end
    end
  end

  context 'when current_user is a common cartridge student ' do
    let(:student) { build_stubbed(:cartridge_student) }
    let(:program) { create(:program) }
    let(:section) { create(:section, program: program) }
    let(:activity) { build_stubbed(:activity) }
    let(:school) { build_stubbed(:school) }

    before do
      build_stubbed(:school_user, user: student, school: school)
      build_stubbed(:cartridge_student_user_link, user: student, school: school)
      allow(controller).to receive(:current_user).and_return(student)
    end

    context 'when a student does not have access to a program' do
      before do
        allow(Maestro::User).to receive(:accessible_programs).with(student.guid).and_return([])
        allow(student).to receive(:cartridge?).and_return(true)
      end

      it 'redirects to the activity access denied page' do
        get :show, params: { id: activity.id, program_id: program.id }
        expect(response).to redirect_to cartridge_access_denied_path(activity.id)
      end

      it 'sends the cartridge? message' do
        get :show, params: { id: activity.id, program_id: program.id }
        expect(student).to have_received(:cartridge?)
      end
    end

    context 'when a student does have access to a program' do
      before do
        allow(Maestro::User).to receive(:accessible_programs)
          .with(student.guid).and_return([program])
      end

      it 'returns a successful status' do
        get :show, params: { id: activity.id, program_id: program.id }
        expect(response).to be_successful
      end

      it 'displays the activity' do
        get :show, params: { id: activity.id, program_id: program.id }
        expect(response.body).to eq('fake render')
      end
    end
  end
end

describe ApplicationController, 'redirect_if_assistant filter' do
  let(:program) { build_stubbed(:program) }
  let(:user) { build_stubbed(:instructor) }
  let(:focus) { double(Focus) }
  let(:assistant_role_policy) { double(AssistantRolePolicy, is_assistant?: false) }

  controller do
    before_action :redirect_if_assistant

    def index
      render plain: 'empty method'
    end
  end

  before do
    allow(controller).to receive(:current_focus).and_return(focus)
    allow(controller).to receive(:current_program).and_return(program)
    allow(controller).to receive(:current_user).and_return(user)
    allow(AssistantRolePolicy).to receive(:new).and_return(assistant_role_policy)
  end

  it 'instantiates a new AssistantRolePolicy, passing in current_focus and current_user' do
    expect(AssistantRolePolicy).to receive(:new).with(focus, user).and_return(assistant_role_policy)
    get :index
  end

  context 'when the current user is not an assistant' do
    it 'does not block access' do
      allow(assistant_role_policy).to receive(:is_assistant?).and_return(false)
      get :index
      expect(response).to be_successful
    end
  end

  context 'when the current user is an assistant' do
    it 'sets a flash error and redirects to the dashboard for a non-AJAX request' do
      allow(assistant_role_policy).to receive(:is_assistant?).and_return(true)
      get :index
      expect(flash[:error]).to eq('You must have Instructor access to view the requested page.')
      expect(response).to redirect_to(instructor_dashboard_path(program))
    end

    it 'returns a not-authorized status code and body text containing an error message for an AJAX request' do
      allow(assistant_role_policy).to receive(:is_assistant?).and_return(true)
      get :index, xhr: true
      expect(response.body).to include('User must have Instructor access')
      expect(response.status).to eq(401)
    end
  end
end

describe ApplicationController, 'require_instructor_or_grader filter' do
  controller do
    before_action :require_instructor_or_grader

    def index
      render plain: 'empty method'
    end
  end

  context 'when current_user is set' do
    let(:user) { build_stubbed(:user) }

    context 'when current_user is a instructor' do
      it 'returns true.' do
        allow(user).to receive(:instructor?).and_return(true)
        allow(@controller).to receive(:current_user).and_return(user)
        get :index
        expect(response).to be_successful
      end
    end

    context 'when current_user is a grader' do
      it 'returns true' do
        allow(user).to receive(:instructor?).and_return(false)
        allow(user).to receive(:grader?).and_return(true)
        allow(@controller).to receive(:current_user).and_return(user)
        get :index
        expect(response).to be_successful
      end
    end

    context 'when current_user is neither a instructor nor a grader' do
      before do
        allow(user).to receive(:instructor?).and_return(false)
        allow(user).to receive(:grader?).and_return(false)
        allow(@controller).to receive(:current_user).and_return(user)
      end

      context 'when the request is not ajax' do
        it 'sets the flash' do
          get :index
          expect(flash[:error]).to eq('You must have Instructor access to view the requested page.')
        end

        it 'redirects to the ua login' do
          get :index
          expect(response).to redirect_to(ua_home_path)
        end
      end

      context 'when the request is ajax' do
        it 'returns 401 status and approirate error message' do
          get :index, xhr: true
          expect(response.body).to include('User must have Instructor or Grader access')
          expect(response.status).to eq(401)
        end
      end
    end
  end
end

describe ApplicationController, 'require_student filter' do
  controller do
    before_action :require_student

    def index
      render plain: 'empty method'
    end
  end

  it 'requires user if current_user is not set' do
    allow(@controller).to receive(:current_user).and_return(nil)
    expect(@controller).to receive(:require_user).and_return(true)
    get :index
  end

  context 'when current_user is set' do
    let(:user) { build_stubbed(:user) }

    context 'when current_user is a student' do
      it 'returns true' do
        allow(user).to receive(:student?).and_return(true)
        allow(@controller).to receive(:current_user).and_return(user)
        get :index
        expect(response).to be_successful
      end
    end

    context 'when current_user is not a student' do
      before do
        allow(user).to receive(:student?).and_return(false)
        allow(@controller).to receive(:current_user).and_return(user)
      end

      context 'when the request is not ajax' do
        it 'sets the flash' do
          allow(BestDefaultPath).to receive(:best_default_path).and_return('/')
          get :index
          expect(flash[:error]).to eq('You must have Student access to view the requested page.')
        end

        it 'redirects to best default path' do
          expect(BestDefaultPath).to receive(:best_default_path).and_return('/best_default_path')
          get :index
          expect(response).to redirect_to('/best_default_path')
        end
      end

      context 'when the request is ajax' do
        it 'returns 401 status and approirate error message' do
          get :index, xhr: true
          expect(response.body).to include('User must have Student access')
          expect(response.status).to eq(401)
        end
      end
    end
  end
end

describe ApplicationController, 'get_from_session_and_delete' do
  controller do
    attr_accessor :results

    def index
      @results = get_from_session_and_delete(:test_value)
      render plain: 'success'
    end
  end

  it 'returns nil if not defined' do
    get :index
    expect(@controller.results).to be_nil
  end

  it 'returns the value if defined' do
    session[:test_value] = 'testing 1 2 3'
    get :index
    expect(@controller.results).to eq('testing 1 2 3')
  end

  it 'removes the retrieved value from the session' do
    session[:test_value] = 'testing 1 2 3'
    get :index
    expect(session[:test_value]).to be_nil
  end

  it 'removes only the target value' do
    session[:test_value] = 'testing 1 2 3'
    session[:leave_me_alone] = 'still_here'
    get :index
    expect(session[:test_value]).to be_nil
    expect(session[:leave_me_alone]).to eq('still_here')
  end
end

describe ApplicationController, 'current_section_id' do
  controller do
    before_action :current_section_id

    def index
      render plain: 'empty method'
    end
  end

  before do
    allow(controller).to receive(:current_focus).and_return(double(Focus, sections: []))
  end

  it 'returns section id if param is passed' do
    get :index, params: { section_id: '5' }
    expect(assigns(:current_section_id)).to eq('5')
  end

  it "returns '0' if no section_id param is passed" do
    get :index
    expect(assigns(:current_section_id)).to eq('0')
  end

  it 'returns section id if guid is passed' do
    section = create(:section_with_course)
    get :index, params: { section_id: section.guid, course_id: section.course.guid, guids: true }
    expect(assigns(:current_section_id)).to eq(section.guid)
  end
end

describe ApplicationController, 'set_time_zone' do
  controller do
    def index
      render plain: 'empty method'
    end
  end

  context 'when there is no user logged in' do
    it 'sets the time zone to Eastern' do
      expect(Time).to receive(:zone=).with('Eastern Time (US & Canada)')
      get :index
    end
  end

  context 'when the logged in user has a nil time zone' do
    it 'sets the time zone to Eastern' do
      fake_login(build_stubbed(:user, time_zone: nil))
      expect(Time).to receive(:zone=).with('Eastern Time (US & Canada)')
      get :index
    end
  end

  context 'when the logged in user has an empty string for time zone' do
    it 'sets the time zone to Eastern' do
      fake_login(build_stubbed(:user, time_zone: ''))
      expect(Time).to receive(:zone=).with('Eastern Time (US & Canada)')
      get :index
    end
  end

  context 'when the logged in user has a non-blank time zone' do
    it 'sets the time zone to the time zone of that user' do
      fake_login(build_stubbed(:user, time_zone: 'Alaska'))
      expect(Time).to receive(:zone=).with('Alaska')
      get :index
    end
  end
end

describe ApplicationController, '#ignore_requests_with_busted_in_params' do
  let(:user) { FactoryBot.build(:user) }

  controller do
    before_action :ignore_requests_with_busted_in_params

    def index
      render plain: 'ignore me.'
    end
  end

  it 'renders an empty string when busted param is present' do
    fake_login(user)

    get :index, params: { busted: 1 + rand(10) }

    expect(response.status).to eq 404
  end

  it 'renders the expected info when busted param is not present' do
    fake_login(user)

    get :index

    expect(response.status).to eq 200
    expect(response.body).to eq 'ignore me.'
  end
end

describe ApplicationController, '#block_demo_users' do
  controller do
    before_action :block_demo_users

    def index
      render plain: 'empty method'
    end
  end

  it 'should show message if in demo' do
    @user = create(:instructor)
    allow(@user).to receive(:demo_only?).and_return(true)
    fake_login(@user)
    get :index
    expect(response).to render_template('home/not_available_in_demo')
  end
end

describe ApplicationController, '#block_clever_rostering_users' do
  let(:program) { create(:program) }
  let(:section) { create(:section) }

  before do
    allow(controller).to receive(:current_program).and_return(program)
  end

  controller do
    before_action :require_user, :block_clever_rostering_users
    def index
      render plain: 'not blocked'
    end
  end

  it 'redirects clever rostering users to the roster view' do
    gradebook_redirect = { controller: 'roster',
                           action: 'show',
                           program_id: program.id,
                           section_id: section.id }

    @user = build_stubbed(:instructor)
    allow(@user).to receive(:rostering?).and_return(true)
    allow(@controller).to receive(:focused_course).and_return(build(:course))
    allow(@controller).to receive(:current_program).and_return(program)
    allow(@controller).to receive(:current_section).and_return(section)
    fake_login(@user)
    get :index
    expect(response.redirect_url).to eq(controller.url_for(gradebook_redirect))
  end

  it 'does not redirect clever users' do
    @user = build_stubbed(:student)
    allow(@user).to receive(:rostering?).and_return(false)
    allow(@user).to receive(:clever?).and_return(true)
    fake_login(@user)
    get :index

    expect(response.redirect_url).to be_nil
    expect(response.body).to eq('not blocked')
  end

  it 'does not redirect other users' do
    @user = build_stubbed(:student)
    allow(@user).to receive(:rostering?).and_return(false)
    allow(@user).to receive(:clever?).and_return(false)
    fake_login(@user)
    get :index

    expect(response.redirect_url).to be_nil
    expect(response.body).to eq('not blocked')
  end
end

describe ApplicationController, 'current_section' do
  controller do
    before_action :current_section

    def index
      render plain: 'empty method'
    end
  end

  let(:user) { build_stubbed(:user) }

  before { fake_login(user) }

  it 'does not delete cookie if the current_user is nil', test_debt: true do
    @user = build_stubbed(:user)
    fake_login(@user)
    cookies[M3::Application.config.fall_back_user_key] = @user.id
    allow(@controller).to receive(:current_user).and_return(nil)
    get :index
    skip
    expect(cookies[M3::Application.config.fall_back_user_key]).to eq(@user.id)
  end

  context 'when section zero' do
    it 'sets current_section to section zero' do
      get :index, params: { section_id: 0 }
      expect(assigns(:current_section)).to be_zero
    end
  end

  context 'when section id is non-zero' do
    let(:section) { create(:section) }

    it 'sets current_section based on the section id passed' do
      get :index, params: { section_id: section.id }
      expect(assigns(:current_section)).to be_non_zero
    end
  end

  context 'when enterprise section' do
    let(:section) { create(:enterprise_section) }

    it 'sets current_section properly' do
      get :index, params: { section_id: section.id }
      expect(assigns(:current_section)).to be_nil
    end
  end

  context 'when in institution admin' do
    before do
      controller.instance_variable_set(:@in_institution_admin, true)
    end

    context 'when enterprise section' do
      let(:section) { create(:enterprise_section) }

      it 'sets current_section properly' do
        get :index, params: { section_id: section.id }
        expect(assigns(:current_section)).to be_non_zero
      end
    end

    context 'when non-enterprise section' do
      let(:section) { create(:section) }

      it 'sets current_section properly' do
        get :index, params: { section_id: section.id }
        expect(assigns(:current_section)).to be_non_zero
      end
    end
  end
end

describe ApplicationController, 'set_fall_back_user' do
  controller do
    before_action :set_fall_back_user

    def index
      render plain: 'empty method'
    end
  end

  it 'does not assign fallback user when fallback user id cookie is nil' do
    @user = build_stubbed(:user)
    fake_login(@user)
    expect(User).not_to receive(:find)
    get :index
    expect(assigns(:fall_back_user)).to be_nil
  end

  it 'deletes the cookie if the current_user is nil', test_debt: true do
    pending 'This test is actually incorrect and not working properly!'
    #No cookies are being deleted, change M3::Application.config.fall_back_user_key
    #to M3::Application.config.fall_back_user_key.to_s, as keys are strings
    @user = build_stubbed(:user)
    cookies[M3::Application.config.fall_back_user_key] = @user.id
    get :index
    expect(cookies[M3::Application.config.fall_back_user_key]).to be_nil
  end

  context 'when fallback user guid cookie is the same as the current_user guid' do
    before do
      @user = build_stubbed(:user)
      fake_login(@user)
      cookies[M3::Application.config.fall_back_user_guid_key] = @user.guid
      get :index
    end

    it 'does not assign fallback user' do
      expect(assigns(:fall_back_user)).to be_nil
    end
  end

  it 'assigns fallback user when cookies contains fallback user guid and the guid is not the current_user guid' do
    @user = build_stubbed(:user)
    fake_login(@user)
    @another_user = build_stubbed(:user)
    cookies[M3::Application.config.fall_back_user_guid_key] = @another_user.guid
    allow(User).to receive(:where).with(guid: @another_user.guid).and_return([@another_user])
    get :index
    expect(assigns(:fall_back_user)).to eq(@another_user)
  end
end

describe ApplicationController, '#vhl_return_to_sanitizer' do
  controller do
    def index
      @return_to = vhl_return_to_sanitizer(params[:return_to])
      head :ok
    end
  end

  it 'returns the ua home path if the domain not of form *.vhlcentral.com' do
    get :index, params: { return_to: 'http://www.abc.com/dangerous' }
    expect(assigns(:return_to)).to eql(ua_home_path)
  end

  it 'returns the unescaped path if the domain is of form *.vhlcentral.com' do
    get :index, params: { return_to: 'http://www.vhlcentral.com/awesome' }
    expect(assigns(:return_to)).to eq('http://www.vhlcentral.com/awesome')
  end

  it 'handles urls with the enforce_utf8 query param as the first param' do
    get :index, params: {
      return_to: "https://www.vhlcentral.com/?utf8=\u2713&a=1"
    }

    expect(assigns(:return_to)).to eq('https://www.vhlcentral.com/?a=1')
  end

  it 'handles urls with the enforce_utf8 query param as last param' do
    get :index, params: {
      return_to: "https://www.vhlcentral.com/?a=1&utf8=\u2713"
    }

    expect(assigns(:return_to)).to eq('https://www.vhlcentral.com/?a=1&')
  end

  it 'handles urls with the enforce_utf8 query param as middle param' do
    get :index, params: {
      return_to: "https://www.vhlcentral.com/?a=1&utf8=\u2713&b=2"
    }

    expect(assigns(:return_to)).to eq('https://www.vhlcentral.com/?a=1&b=2')
  end

  it 'handles urls with the enforce_utf8 query param cgi encoded as the first param' do
    get :index, params: {
      return_to: '/?utf8=%E2%9C%93&a=1'
    }

    expect(assigns(:return_to)).to eq('/?a=1')
  end

  it 'handles urls with the enforce_utf8 query param cgi encoded as the last param' do
    get :index, params: {
      return_to: '/?a=1&utf8=%E2%9C%93'
    }

    expect(assigns(:return_to)).to eq('/?a=1&')
  end

  it 'handles urls with the enforce_utf8 query param cgi encoded as the middle param' do
    get :index, params: {
      return_to: '/?a=1&utf8=%E2%9C%93&b=2'
    }

    expect(assigns(:return_to)).to eq('/?a=1&b=2')
  end
end

describe ApplicationController, '#script_tag_sanitizer' do
  it 'removes out script tags and their content' do
    content = "<script>console.log('i am bad')script stuff</script>My text"
    clean_content = 'My text'
    expect(controller.script_tag_sanitizer(content)).to eq(clean_content)
  end
end

describe ApplicationController, '#handle_unverified_request' do
  controller do
    protect_from_forgery

    def create
      render plain: 'empty POST'
    end
  end

  before do
    @params = { param1: 'some value' }
    fake_login(build_stubbed(:user))
  end

  context 'when POSTing without authentication_token' do
    it 'handles messaging for Rollbar', test_debt: true do
      pending
      with_forgery_protection do
        xception = double('Exception')
        expect(ActionController::InvalidAuthenticityToken).to receive(:new).with('CSRF detected').and_return(xception)
        expect(VHLMonitor).to receive(:notify) do |error, args|
          expect(error).to eq(xception)
          params = args[:parameters]
          expect(params[:method]).to eq('POST')
          expect(params['param1']).to eq('some value')
        end

        post :create, params: @params
      end
    end
  end

private
  def with_forgery_protection
    _old_value = controller.allow_forgery_protection
    controller.allow_forgery_protection = true
    yield
  ensure
    controller.allow_forgery_protection = _old_value
  end
end

describe ApplicationController, '#course_create_edit_policy' do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:policy) { double(Policy::Course::CreateEdit) }

  before do
    allow(controller).to receive(:current_user) { user }
  end

  it 'returns a Policy::Course::CreateEdit instance for current user' do
    expect(Policy::Course::CreateEdit).to receive(:new).with(user) { policy }
    expect(controller.course_create_edit_policy).to eq(policy)
  end

  it 'does not create duplicate instances on subsequent calls' do
    expect(Policy::Course::CreateEdit).to receive(:new).once { policy }
    controller.course_create_edit_policy
    controller.course_create_edit_policy
  end
end

describe ApplicationController, '#pubnub_token' do
  let(:group_key) { instance_double(GroupMembershipKey, key: 'my_valid_key') }
  let(:redis) { double(Redis) }
  let(:auth_token) do
    {
      id: 'mock-authtoken',
      groups: { roster: [{ id: 'section_1', name: 'section_1_name' }] }
    }
  end

  before do
    allow(GroupMembershipKey).to receive(:new).and_return(group_key)
    allow(M3::Application).to receive_message_chain(:config, :chat_auth_cache).and_return(redis)
    allow(redis).to receive(:is_a?).with(Redis).and_return(true)
    allow(redis).to receive(:get).and_return(auth_token.to_json)
  end

  it 'returns an empty JSON object when there is no logged in user' do
    allow(controller).to receive(:current_user).and_return(nil)

    expect(controller.pubnub_token).to eq({}.to_json)
  end

  context 'with an instructor,' do
    let(:instructor) { build_stubbed(:instructor) }

    before do
      allow(controller).to receive(:current_user).and_return(instructor)
    end

    it 'generates a GroupMembershipKey with the current user' do
      controller.pubnub_token

      expect(GroupMembershipKey).to have_received(:new).with(instructor)
    end

    it 'looks up the AuthToken in redis using the GroupMembershipKey' do
      controller.pubnub_token

      expect(redis).to have_received(:get).with(group_key.key)
    end

    it 'returns an empty JSON object when there is nothing found in the cache' do
      allow(redis).to receive(:get).and_return(nil)

      expect(controller.pubnub_token).to eq({}.to_json)
    end

    it 'returns an existing auth token found in the cache' do
      expect(controller.pubnub_token).to eq(auth_token.to_json)
    end
  end

  context 'with a student,' do
    let(:student) { build_stubbed(:student) }

    before do
      allow(controller).to receive(:current_user).and_return(student)
    end

    it 'returns an empty JSON object if current section is zero' do
      section_zero = build_stubbed(:section, id: 0)
      allow(controller).to receive(:current_section).and_return(section_zero)

      expect(controller.pubnub_token).to eq({}.to_json)
    end

    it "returns an empty JSON object if current section's course has chat disabled" do
      course = build_stubbed(:course, chat_level: 'disabled')
      section = build_stubbed(:section, course: course)
      allow(controller).to receive(:current_section).and_return(section)

      expect(controller.pubnub_token).to eq({}.to_json)
    end

    context 'with a non-zero section in a course with chat enabled' do
      let(:section) { build_stubbed(:section, course: course) }
      let(:course) { build_stubbed(:course, chat_level: 'partner_chat') }

      before do
        allow(controller).to receive(:current_section).and_return(section)
      end

      it 'generates a GroupMembershipKey with the current user' do
        controller.pubnub_token

        expect(GroupMembershipKey).to have_received(:new).with(student)
      end

      it 'looks up the AuthToken in redis using the GroupMembershipKey' do
        controller.pubnub_token

        expect(redis).to have_received(:get).with(group_key.key)
      end

      it 'returns an empty JSON object when there is nothing found in the cache' do
        allow(redis).to receive(:get).and_return(nil)

        expect(controller.pubnub_token).to eq({}.to_json)
      end

      it 'returns an existing auth token found in the cache' do
        expect(controller.pubnub_token).to eq(auth_token.to_json)
      end
    end
  end

  context 'when current user does have an associated auth token in cache' do
    it 'extends the ttl of the existing auth token in cache', test_debt: true do
      # 10800 = 3 hours, which is the threshold used to validate cache.
      allow(redis).to receive(:ttl).and_return(rand(1..10800))
      allow(redis).to receive(:expire)
      controller.pubnub_token

      expect(redis).to have_received(:expire).with(group_key.key, anything)
      expect(redis).to have_received(:ttl).with(group_key.key).at_least(:once)
    end
  end
end

describe ApplicationController, '#assign_lossless_auth_token' do
  let(:group_key) { instance_double(GroupMembershipKey, key: 'valid_key') }
  let(:policy) { instance_double(Lossless::Policy, token: '') }

  before do
    allow(GroupMembershipKey).to receive(:new).and_return(group_key)
    allow(Lossless::Policy).to receive(:new).and_return(policy)
  end

  context 'with no logged in user,' do
    before do
      allow(controller).to receive(:current_user).and_return(nil)
      controller.assign_lossless_auth_token
    end

    it 'does not assign @lossless_auth_token' do
      expect(assigns(:lossless_auth_token)).to be_nil
    end

    it "does not set a flash message warning that recordings won't work" do
      expect(flash[:error]).to be_nil
    end
  end

  context 'with a logged in user,' do
    let(:user) { build_stubbed(:student) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'generates a GroupMembershipKey for the current user' do
      controller.assign_lossless_auth_token

      expect(GroupMembershipKey).to have_received(:new).with(user)
    end

    it 'generates a lossless policy token with the current user and ' \
       'the generated GroupMembershipKey' do
      controller.assign_lossless_auth_token

      expect(Lossless::Policy).to have_received(:new).with(group_key.key, user)
    end

    context 'when the lossless policy token is generated successfully,' do
      let(:valid_policy_token) { 'valid_token' }

      before do
        allow(policy).to receive(:token).and_return(valid_policy_token)
        controller.assign_lossless_auth_token
      end

      it 'assigns @lossless_auth_token to the generated token' do
        expect(assigns(:lossless_auth_token)).to eq(valid_policy_token)
      end

      it "does not set a flash message warning that recordings won't work" do
        expect(flash[:error]).to be_nil
      end
    end

    context 'when the lossless policy token fails to generate,' do
      before do
        allow(policy).to receive(:token).and_return(nil)
        controller.assign_lossless_auth_token
      end

      it 'does not assign @lossless_auth_token' do
        expect(assigns(:lossless_auth_token)).to be_nil
      end

      it "sets a flash message warning that recordings won't work" do
        expect(flash[:error]).to match(/error.*recording.*save.*play/)
      end
    end
  end
end

describe ApplicationController, '#ensure_safe_protocol' do
  it 'allows valid schemes: no scheme, "http", and "https"' do
    %w[//example.com
       http://example.com
       https://example.com].each do |scheme|
      url = "#{scheme}://example.com"
      expect(controller.ensure_safe_protocol(url)).to eq(url)
    end
  end

  it 'raises an error for invalid schemes, e.g. javascript' do
    url = 'javascript://example.com'
    expect { controller.ensure_safe_protocol(url) }.to raise_error(ArgumentError)
  end
end

describe ApplicationController, '#svr_activity_page?' do
  context 'when @activity is defined' do
    before do
      activity = create(:activity, activity_type: 'solo_video_recording')
      controller.instance_variable_set(:@activity, activity)
    end

    it 'returns true if activity type is solo_video_recording' do
      expect(controller.send(:svr_activity_page?)).to be_truthy
    end
  end

  context 'when @activity is defined but activity type is other than solo_video_recording' do
    before do
      activity = create(:activity, activity_type: 'some_other_activity')
      controller.instance_variable_set(:@activity, activity)
    end

    it 'returns false if activity type is other than solo_video_recording' do
      expect(controller.send(:svr_activity_page?)).to be_falsey
    end
  end

  context 'when @activity is not defined' do
    it 'returns false' do
      expect(controller.send(:svr_activity_page?)).to be_falsey
    end
  end
end

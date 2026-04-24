require 'instructor/announcements_controller'

describe Instructor::AnnouncementsController do
  let(:program) { create(:program_with_toc_entries) }
  let(:user) { create(:instructor) }
  let(:course) { create(:course, program: program) }
  let!(:section) { create(:section, course: course) }

  before do
    populate_instructor_program_and_focus
    allow(user).to receive(:has_current_access_to?).and_return(true)
  end

  describe '#index' do
    before do
      fake_login(user)
    end

    def do_request
      get :index, params: { program_id: program.id }
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    it 'should render the index view' do
      do_request
      expect(@controller).to render_template 'instructor/announcements/index'
    end

    it 'should populate a list of announcements that correspond to the specific course' do
      list_of_announcements = [double('Announcement')]
      allow(@focus).to receive(:sections).and_return(course.sections)
      expect(Announcement).to receive(:by_section).with(*course.sections)
        .and_return(list_of_announcements)
      do_request
      expect(assigns(:announcements)).to eq(list_of_announcements)
    end
  end

  describe '#new' do
    before do
      allow(Program).to receive(:find).and_return(program)
      allow(Section).to receive(:find).and_return(section)
      fake_login(user)
    end

    def do_request
      get :new, params: { program_id: program.id }
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    it 'should instantiate and assign a new announcement' do
      announcement = build(:announcement)
      expect(Announcement).to receive(:new).and_return(announcement)
      do_request
      expect(assigns(:announcement)).to eq(announcement)
    end
  end

  describe '#edit' do
    let!(:announcement) { build_stubbed(:announcement) }

    before do
      allow(Program).to receive(:find).and_return(program)
      allow(Section).to receive(:find).and_return(section)
      allow(Announcement).to receive(:find).with(announcement.id.to_s).and_return(announcement)
      fake_login(user)
    end

    def do_request(params = {})
      get :edit, params: { program_id: program.id, id: announcement.id }.merge(params)
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    it 'should obtain the announcement to be edited and check it is assigned' do
      announcement = build_stubbed(:announcement)
      expect(Announcement).to receive(:find).with(announcement.id.to_s).and_return(announcement)
      do_request id: announcement.id
      expect(assigns(:announcement)).to eq(announcement)
    end

    it 'should assign a page title' do
      do_request
      expect(assigns(:page_title)).to eq('Edit announcement')
    end
  end

  describe '#destroy' do
    let!(:announcement) { create(:announcement, author: user) }

    before do
      allow(Program).to receive(:find).and_return(program)
      allow(Section).to receive(:find).and_return(section)
      fake_login(user)
    end

    def do_request
      delete :destroy, params: { program_id: program.id, id: announcement.id }
    end

    it_should_behave_like 'an action that requires a logged in instructor'

    it 'should archive the announcement' do
      do_request
      archived_announcement = Announcement.unscoped.find(announcement.id)
      expect(archived_announcement.is_archived?).to be true
    end

    context 'on success' do
      it 'should set a flash message informing that the announcement has been deleted' do
        do_request
        expect(flash[:notice]).to eq("The announcement '#{announcement.title}' has been deleted.")
      end

      it 'should redirect to the announcement index' do
        do_request
       expect(response).to redirect_to instructor_announcements_path(program.id)
      end
    end

    context 'on failure' do
      it "should display the 'edit' view" do
        allow(Announcement).to receive(:find).with(announcement.id.to_s).and_return(announcement)
        announcements_stub = user.announcements
        allow(announcements_stub).to receive(:where).with(id: announcement.id.to_s)
                                                    .and_return([announcement])
        allow(announcement).to receive(:update).and_return(false)
        do_request
        expect(response).to render_template 'edit'
      end
    end
  end
end

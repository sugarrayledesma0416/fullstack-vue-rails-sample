describe AnnouncementsController do
  let(:program) { build_stubbed(:program) }
  let(:section) { build_stubbed(:section_with_course) }
  let(:student) { build_stubbed(:student) }
  let(:announcement) { build_stubbed(:announcement) }
  let(:announcement_notification) { build_stubbed(:announcement_posted_notification, section: section, user: student) }

  before do
    allow(HelpEntry).to receive(:first)
    allow(Section).to receive(:find_by).and_return(section)
    allow(section).to receive(:program).and_return(program)
    allow(student).to receive(:has_current_access_to?).and_return(true)
  end

  describe '#index' do
    before do
      fake_login(student)

      allow(Notification).to receive(:communications).and_return([announcement_notification])
    end

    def do_request(params = {})
      get :index, params: { section_id: section.id }.merge(params)
    end

    it_behaves_like 'an action that requires a logged in user'
    it_behaves_like 'an action that requires program access'
    it_behaves_like 'an action that assigns contextual help'

    it 'stores the activity return link to announcements index' do
      do_request
      expect(session[:activity_return]['label']).to eq('Return to Announcements')
      expect(session[:activity_return]['url']).to eq(section_announcements_path(section.id))
    end
  end

  describe '#show' do
    before do
      fake_login(student)

      allow(Announcement).to receive(:find).and_return(announcement)
      allow(announcement).to receive(:dismiss_notifications_for_user_and_section)
    end

    def do_request
      get :show, params: { section_id: section.id, id: announcement.id }
    end

    it_behaves_like 'an action that requires a logged in user'
    it_behaves_like 'an action that requires program access'
    it_behaves_like 'an action that assigns contextual help'

    it 'finds and assigns the announcement matching the specified id' do
      expect(Announcement).to receive(:find).with(announcement.id.to_s).and_return(announcement)
      do_request
      expect(assigns(:announcement)).to eq(announcement)
    end

    it 'assigns current section as @section' do
      do_request
      expect(assigns(:section)).to eq(section)
    end

    it 'marks announcement notifications for the current user and section as dismissed' do
      expect(announcement).to receive(:dismiss_notifications_for_user_and_section).with(student, section)
      do_request
    end
  end

  describe '#download' do
    before do
      fake_login(student)

      allow(Announcement).to receive(:find).and_return(announcement)
    end

    def do_request(params = {})
      get :download, params: { section_id: section, id: announcement.id }
    end

    it_behaves_like 'an action that requires program access'

    context 'when valid params are specified' do
      it 'finds and redirects to the uploaded file for the specified announcement id' do
        file_url = 'https://test.dom/test.jpg'
        allow(announcement).to receive(:signed_url).and_return(file_url)
        allow(announcement).to receive(:file_name).and_return('test.jpg')
        allow(announcement).to receive(:file_path).and_return("#{Rails.root}/spec/fixtures/media_items/test.jpg")
        allow(Announcement).to receive(:find).with(announcement.id.to_s).and_return(announcement)
        do_request
        expect(response).to redirect_to(file_url)
      end
    end

    it 'redirects to 404 when no file exists for the specified announcement id' do
      allow(announcement).to receive(:has_file?).and_return(false)
      allow(announcement).to receive(:file_path).and_return(nil)
      do_request
      expect(response).to redirect_to('/404')
    end
  end
end


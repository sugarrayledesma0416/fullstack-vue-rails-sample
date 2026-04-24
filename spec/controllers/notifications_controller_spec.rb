describe NotificationsController do
  let(:program) { build_stubbed(:program) }
  let(:section) { build_stubbed(:section_with_course) }
  let(:student) { build_stubbed(:student) }
  let(:activity) { build_stubbed(:activity) }
  let(:activity_notification) { build_stubbed(:activity_graded_notification, section: section, activity: activity) }

  before do
    allow(HelpEntry).to receive(:find)
    allow(Section).to receive(:find_by).and_return(section)
    allow(section).to receive(:program).and_return(program)
    allow(student).to receive(:has_current_access_to?).and_return(true)
  end

  describe '#index' do
    let(:nt_filter) { double('NotificationsFilter', notifications: [activity_notification]) }

    before do
      fake_login(student)
      allow(NotificationsFilter).to receive(:new).and_return(nt_filter)
      allow(nt_filter).to receive(:notifications).and_return([activity_notification])
    end

    def do_request(params = {})
      get :index, params: { section_id: section.id }.merge(params)
    end

    it_behaves_like 'an action that requires a logged in user'
    it_behaves_like 'an action that requires program access'
    it_behaves_like 'an action that assigns contextual help'

    it 'should store the activity return link to notifications index' do
      do_request
      expect(session[:activity_return]['label']).to eql('Return to Notifications')
      expect(session[:activity_return]['url']).to eql(section_notifications_path(section.id))
    end
  end

  describe '#show' do
    before do
      fake_login(student)
      allow(Notification).to receive(:find).and_return(activity_notification)
    end

    def do_request
      get :show, params: { section_id: section.id.to_s, id: activity_notification.id.to_s }
    end

    it_behaves_like 'an action that requires a logged in user'
    it_behaves_like 'an action that requires program access'
    it_behaves_like 'an action that assigns contextual help'

    it 'finds and assigns a notification based on the specified id' do
      do_request

      expect(Notification).to have_received(:find)
        .with(activity_notification.id.to_s)

      expect(assigns(:notification)).to eq(activity_notification)
    end

    context 'when the notification is for an internal activity,' do
      it 'redirects to the show page for the specified activity' do
        do_request

        expect(response).to redirect_to section_activity_path(section, activity)
      end
    end

    context 'when the notification has a redirect path of study_plan,' do
      it 'redirects to the study plan concepts path' do
        allow(activity_notification).to receive(:redirect_type)
          .and_return(:study_plan)

        do_request

        expect(response).to redirect_to section_study_plan_concepts_path(section, activity)
      end
    end

    context 'when the notification has a redirect path of study_plan_v2,' do
      it 'redirects to the activity path' do
        allow(activity_notification).to receive(:redirect_type)
          .and_return(:study_plan_v2)

        do_request

        expect(response).to redirect_to section_activity_path(section, activity)
      end
    end

    context 'when the notification is for an announcement,' do
      let(:announcement) { build_stubbed(:announcement) }
      let(:announcement_notification) do
        build_stubbed(
          :announcement_posted_notification,
          announcement: announcement,
          section: section
        )
      end

      before do
        allow(announcement_notification).to receive(:redirect_type)
          .and_return(:announcement)
        allow(Notification).to receive(:find).and_return(announcement_notification)
      end

      it 'redirects to the non-Supersite Junior show page for the specified ' \
         'announcement when the current program is not Supersite Junior' do
        do_request

        expect(response).to redirect_to(
          section_announcement_path(section, announcement)
        )
      end

      it 'redirects to the Supersite Junior show page for the specified ' \
         'announcement when the current program is Supersite Junior' do
        allow(section).to receive(:program)
          .and_return(build_stubbed(:ss_jr_program))

        do_request

        expect(response).to redirect_to(
          jr_section_announcement_path(
            id: announcement.id, section_id: section.id
          )
        )
      end
    end
  end
end

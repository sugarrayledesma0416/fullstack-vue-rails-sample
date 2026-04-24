shared_examples 'an action that finds and assigns activity by id' do
  it 'finds activity by id and assigns it' do
    ensure_correct_section(section)
    fake_login(@user)

    expect(scope).to receive(:find).with(@activity.id.to_s).and_return(@activity)

    do_request
    expect(assigns(:activity)).to eq(@activity)
  end
end

shared_examples 'an action that requires the program access' do
  it 'requires the program access' do
    expect(controller).to receive(:require_program_access)
    do_request
  end
end

shared_examples 'an action that ensures the correct section' do
  it 'ensures the correct section' do
    expect(controller).to receive(:ensure_correct_section)
    do_request
  end
end

shared_examples 'an action that ensures access to the activity' do
  context 'when an activity is not unlisted' do
    it 'returns an error when user does not have access' do
      ensure_correct_section(section)
      fake_login(@user)
      allow(@activity).to receive(:listed?).and_return(true)
      allow(access_guardian).to receive(:can_access_content?).and_return(false)

      do_request
      expect(flash[:error]).to eq(message)
    end
  end

  context 'when an activity is unlisted' do
    it 'does not return an error when user does not have access' do
      ensure_correct_section(section)
      fake_login(@user)
      allow(@activity).to receive(:listed?).and_return(false)

      do_request
      expect(flash[:error]).to be_nil
    end

    it 'does not return an error when user is not a student' do
      allow(user).to receive(:has_current_access_to?).and_return(true)
      allow(user).to receive(:cartridge?).and_return(true)
      ensure_correct_section(section)
      fake_login(user)
      allow(@activity).to receive(:listed?).and_return(false)

      do_request
      expect(flash[:error]).to be_nil
    end
  end
end

shared_examples 'an action that finds and assigns activity by cms_activity_id' do
  let(:program) { FactoryBot.build(:program, id: 1) }

  before do
    attempt = build_stubbed(:attempt, cms_revision_id: 222)
    allow(attempt).to receive(:attempt_track)
      .and_return(double 'AttemptTrack')
    allow(attempt).to receive(:activity=)
    allow(@classwork).to receive(:find_or_new_attempt).and_return(attempt)
    allow(@controller).to receive(:current_program).and_return(program)
  end

  context 'when no program_id param is passed,' do
    it 'tries to retrieve the program id from the current program' do
      @params.merge!(id: '0')

      expect(Activity).to receive(:find_by_cms_activity_id_in_program).with('0', program.id)
                                                                      .and_return(@activity)

      do_request @params
    end

    it 'raises a 404 error when is not possible to get a program id' do
      @params.merge!(id: '0')

      allow(@controller).to receive(:current_program).and_return(nil)
      allow(Activity).to receive(:find_by_cms_activity_id_in_program).with('0', nil)

      expect { do_request @params }.to raise_error(::ActionController::RoutingError)
    end
  end

  context 'when a program_id param is passed,' do
    it 'finds activity by cms_activity_id and program_id and assigns it' do
      program_id = '1234'
      ensure_correct_section(section)
      fake_login(@user)
      attempt = build_stubbed(:attempt)
      allow(attempt).to receive(:activity=)
      allow(@classwork).to receive(:find_or_new_attempt).and_return(attempt)
      allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
      allow(presenter).to receive(:find_or_create_attempt).and_return(attempt)

      expect(Activity).to receive(:find_by_cms_activity_id_in_program)
        .with(@activity.cms_activity_id.to_s, program_id)
        .and_return(@activity)

      do_request(program_id: program_id)
      expect(assigns(:activity)).to eq @activity
    end
  end

  context 'when activity is not found' do
    it 'raises a 404' do
      @params.merge!(id: 0)
      allow(@controller).to receive(:current_program).and_return(nil)
      allow(Activity).to receive(:find_by_cms_activity_id_in_program).with('0', nil).and_return(nil)
      expect { do_request @params }.to raise_exception(::ActionController::RoutingError)
    end
  end
end

shared_examples 'an action that assigns an activity presenter' do
  it 'creates and assigns a new presenter, specifying current activity, user, and section' do
    ensure_correct_section(section)
    fake_login(@user)

    expect(StudentActivityPresenter).to receive(:new).with(@activity, @user, section).and_return(presenter)
    do_request
    expect(assigns(:activity_presenter)).to eq(presenter)
  end
end

shared_examples 'an action that assigns video settings from the presenter' do
  it "assigns the presenter's video settings" do
    ensure_correct_section(section)
    fake_login(@user)
    allow(presenter).to receive(:video_settings).and_return('expected_video_settings')
    do_request
    expect(assigns(:video_settings)).to eq('expected_video_settings')
  end
end

shared_examples 'an action that logs an activity time to low error' do
  it 'writes the error description and request properties to the general log' do
    expect(GeneralLog).to receive(:create).with(hash_including(log_type: 'ActivityStartTimeTooLow', data_format: 'json'))
    do_request
  end
end

shared_examples 'an action that logs an activity time spent to high error' do
  it 'writes the error description and request properties to the general log' do
    expect(GeneralLog).to receive(:create).with(hash_including(log_type: 'ActivityTimeSpentTooHigh', data_format: 'json'))
    do_request
  end
end

shared_examples 'an action that logs an activity time_spent not a digit error' do
  it 'writes the error description and request properties to the general log' do
    expect(GeneralLog).to receive(:create).with(hash_including(log_type: 'ActivityTimeContainsNonDigit', data_format: 'json'))
    do_request
  end
end

shared_examples 'an action that logs an activity start time blank error' do
  it 'writes the error description and request properties to the general log' do
    expect(GeneralLog).to receive(:create).with(hash_including(log_type: 'ActivityStartTimeBlank', data_format: 'json'))
    do_request
  end
end

shared_examples 'an action that handles timespent error cases' do
  context 'when the the time spent is higher than 1 hour' do
    let(:start_time) { 1348582475 }
    let(:end_time) { 1348586076 }

    before do
      @start_time = start_time
      allow(@controller).to receive(:time_now_in_seconds).and_return(end_time)
    end

    it_behaves_like 'an action that logs an activity time spent to high error'
  end

  context 'when the start_time is zero' do
    let(:start_time) { 0 }
    let(:end_time) { 1348586076 }

    before do
      @start_time = start_time
      allow(@controller).to receive(:time_now_in_seconds).and_return(end_time)
    end

    it_behaves_like 'an action that logs an activity start time blank error'
  end

  context 'when start_time is low, meaning before May 1 2012' do
    let(:start_time) { Time.parse('2012-04-30T23:59:59.000-00:00').to_i }
    let(:end_time) { 1348586076 }

    before do
      @start_time = start_time
      allow(@controller).to receive(:time_now_in_seconds).and_return(end_time)
    end

    it_behaves_like 'an action that logs an activity time to low error'
  end

  context 'when start_time is not a number' do
    let(:start_time) { 'some_text' }
    let(:end_time) { 1348586076 }

    before do
      @start_time = start_time
      allow(@controller).to receive(:time_now_in_seconds).and_return(end_time)
    end

    it_behaves_like 'an action that logs an activity time_spent not a digit error'
  end

  context 'when end_time is not a number' do
    let(:start_time) { 1335844799 }
    let(:end_time) { 'another_text' }

    before do
      @start_time = start_time
      allow(@controller).to receive(:time_now_in_seconds).and_return(end_time)
    end

    it_behaves_like 'an action that logs an activity time_spent not a digit error'
  end
end

shared_examples 'an action that prevents access to a blocked enrollment' do
  context 'when a user has a blocked enrollment' do
    let(:activity) { create(:activity) }
    let(:section) do
      create(
        :section,
        course: create(:course, school: create(:school, school_type_category:))
      )
    end
    let(:link) do
      '<a target="_blank" href="https://support.vhlcentral.com/hc/en-us/requests/new">' \
        'submit a support request</a>'
    end

    before do
      create(:active_enrollment, user: student, section:, blocked: true)
    end

    context 'when a student is not at a K12 school' do
      let(:school_type_category) { 1 }

      it 'prevents all access to the activity shell' do
        message = 'There is a short delay when enrolling. You cannot access the ' \
                  'activities until it is resolved. Please try again after a few minutes. ' \
                  "If you continue to see this message, #{link}"

        fake_login(student)

        get :show, params: { section_id: section.id, id: activity.id }
        expect(flash[:warning]).to eq(message)
        expect(response).to redirect_to(course_section_path(section.course, section))
      end
    end

    context 'when a student is at a K12 school' do
      let(:school_type_category) { 3 }

      it 'prevents all access to the activity shell' do
        message = 'There is a short delay when enrolling. You cannot access the ' \
                  'activities until it is resolved. Please try again after a few minutes. ' \
                  "If you continue to see this message, ask your instructor to help #{link}"

        fake_login(student)

        get :show, params: { section_id: section.id, id: activity.id }
        expect(flash[:warning]).to eq(message)
        expect(response).to redirect_to(course_section_path(section.course, section))
      end
    end
  end
end

shared_examples 'an action that shows an activity' do
  let(:license_group) { double('LicenseGroup', id: 123, name: 'valid license group') }

  before do
    allow(controller).to receive(:require_component_privileges)
    allow(controller).to receive(:assign_section_header)
    @program = build_stubbed(:program)
    @strand = create(:toc_entry)
    @lesson = create(:lesson, toc_entries: [@strand])
    notification_scope = double('Notification')
    allow(notification_scope).to receive(:by_user_and_section).and_return(
      double('Notification', :dismiss_all! => '')
    )
    @activity = create(
      :activity,
      activity_type: activity_type,
      id: 55,
      lesson: @lesson,
      license_group_id: license_group.id,
      max_attempts: 1,
      toc_location: @strand.location
    )

    allow(@activity).to receive(:content_object).and_return(mock_content_object)
    allow(@activity).to receive(:list_header).and_return('lesson foo / strand bar')
    allow(@activity).to receive(:notifications).and_return(notification_scope)
    allow(@activity.content_object).to receive(:external_references).and_return([])
    allow(@activity).to receive(:content_summary).and_return({})
    allow(@activity).to receive(:vtext_link=)
    allow(scope).to receive(:find).and_return(@activity)
    @attempt = build_stubbed(:attempt, cms_revision_id: 222)
    allow(@attempt).to receive(:activity=)
    allow(@attempt).to receive(:activity).and_return(@activity)
    allow(@activity).to receive(:ensure_correct_version)
    allow(@activity).to receive(:santillana?).and_return(false)
    allow(@activity).to receive(:ai_virtual_chat?).and_return(false)

    allow(@attempt).to receive(:common_instructor_feedback).and_return(nil)

    allow(@classwork).to receive(:current_workset)
    allow(@classwork).to receive(:closed_section?).and_return(false)
    @attempt_track = mock_attempt_track()
    allow(AttemptTrack).to receive(:new).and_return(@attempt_track)
    allow(@attempt_track).to receive(:complete=)
    allow(@attempt_track).to receive(:practice=)
    allow(@attempt_track).to receive(:attempt_number=)
    allow(controller.instance_eval { flash }).to receive(:sweep)
    allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
    allow(presenter).to receive(:find_or_create_attempt).and_return(@attempt)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
    ensure_correct_section(nil)
  end

  it_should_require_a_logged_in_user { get :show, params: { id: '37', section_id: '0' } }

  context 'with unstubbed section header,' do
    before do
      allow(controller).to receive(:assign_section_header).and_call_original
    end

    it_should_assign_section_header { get :show, params: { id: '37', section_id: '1' } }
  end

  it 'assigns @activity' do
    fake_login(@user)
    expect(scope).to receive(:find).with('37').and_return(@activity)
    do_request('0', '37')
    expect(assigns(:activity)).to eq(@activity)
  end

  it 'sets the activity to use the same revision that was attempted' do
    fake_login(@user)
    expect(@activity).to receive(:ensure_correct_version).with(@attempt.cms_revision_id)
    do_request('0')
  end


  def do_request(section_id = '1', activity_id = nil, params = {})
    activity_id ||= @activity.id.to_s
    get :show, params: { section_id: section_id, id: activity_id }.merge(params)
  end

  it_behaves_like 'an action that ensures access to the activity' do
    let(:user) { instructor_user }
    let(:message) do
      if @user.cartridge?
        'Sorry, but you do not have access to this item. %s'
      else
        'Sorry, but you cannot access that activity.'
      end
    end
  end
  it_behaves_like 'an action that finds and assigns activity by id'
  it_behaves_like 'an action that assigns an activity presenter' do
    before do
      allow(@user).to receive(:instructor?).and_return(false)
    end
  end
  it_behaves_like 'an action that assigns video settings from the presenter'


  context 'when the presenter returns true for should_show_answers' do
    it 'assigns true to show_correct_answers' do
      ensure_correct_section(section)
      allow(presenter).to receive(:should_show_answers?).and_return(true)

      fake_login(@user)
      do_request(section.id)
      expect(assigns(:show_correct_answers)).to be_truthy
    end
  end

  context 'when the presenter returns false for should_show_answers' do
    it 'assigns false to show_correct_answers' do
      ensure_correct_section(section)
      allow(presenter).to receive(:should_show_answers?).and_return(false)

      fake_login(@user)
      do_request(section.id)
      expect(assigns(:show_correct_answers)).to be_falsey
    end
  end

  context 'when activity is a vocab_list,' do
    before do
      fake_login(@user)
      @content = MaestroActivityEngine::ActivityContent::VocabListContent.new
      allow(@content).to receive(:activity_type).and_return('vocab_list')
      allow(@activity).to receive(:content_object).and_return(@content)
      allow(@content).to receive(:populate_vocab_group_content)
    end

    it 'should do nothing if content object groups have no media' do
      group  = MaestroActivityEngine::ActivityContent::VocabList::Group.new(id: nil)
      column = MaestroActivityEngine::ActivityContent::VocabList::Column.new(vocab_group: [group])
      @content.columns = [column]
      expect(MediaItem).not_to receive(:find)
      expect(group).not_to receive(:base_dir=)
      expect(group).not_to receive(:public_dir=)
      expect(group).not_to receive(:populate_content_from_csv)
      do_request('0')
    end

    context 'when the group has media,' do
      before do
        @media_item = double(MediaItem, id: 123, base_dir: 'base_dir', public_dir: 'public_dir',
                                        unzipped_directory: 'unzipped_directory', csv_content: 'csv_content')
        @group = MaestroActivityEngine::ActivityContent::VocabList::Group.new(id: @media_item.id)
        allow(@group).to receive(:populate_content_from_csv)
        column = MaestroActivityEngine::ActivityContent::VocabList::Column.new(vocab_group: [@group])
        @content.columns = [column]
        allow(MediaItem).to receive(:find).and_return(@media_item)
      end

      it 'should find the media item based on the group id' do
        expect(MediaItem).to receive(:find).with(@group.id).and_return(@media_item)
        do_request('0')
      end

      it "should assign the vocab dir to the group's base dir" do
        expect(@media_item).to receive(:base_dir).and_return('base_dir')
        expect(@group).to receive(:base_dir=).with('base_dir')
        do_request('0')
      end

      it "assigns the unzipped_directory path to the vocab dir to the group's public_dir" do
        expected_path = 'unzipped_directory'
        expect(@media_item).to receive(:unzipped_directory).and_return(expected_path)
        expect(@group).to receive(:public_dir=).with(expected_path)
        do_request('0')
      end

      it 'assigns the content to the vocab group csv_content attribute' do
        expected_content = 'csv_content'
        expect(@media_item).to receive(:csv_content).and_return(expected_content)
        expect(@group).to receive(:content_csv=).with(expected_content)
        do_request('0')
      end

      it 'should pouplate the vocab group data from the csv' do
        expect(@group).to receive(:populate_content_from_csv)
        do_request('0')
      end
    end
  end

  it 'looks up existing attempts' do
    expect(presenter).to receive(:find_or_create_attempt).and_return(@attempt)
    fake_login(@user)
    do_request('0')
  end

  it 'assigns a composition attachment id when present within the params' do
    fake_login(@user)
    do_request('0', nil, attachment_id: 1)
    expect(assigns(:composition_attachment_id)).to eq('1')
  end

  context 'for uploader' do
    before do
      fake_login(@user)
    end

    it_should_behave_like 'an action that assigns allowed file extensions'
  end

  it 'assigns @attempt_track' do
    fake_login(@user)

    @attempt_track = mock_attempt_track()

    allow(AttemptTrack).to receive(:new).and_return(@attempt_track)
    allow(@attempt_track).to receive(:complete=).and_return(false)
    allow(@attempt_track).to receive(:practice=).and_return(false)
    allow(@attempt_track).to receive(:attempt_number=)

    do_request('0')
    expect(assigns(:attempt_track)).to eq(@attempt_track)
  end

  it 'assigns @attempt' do
    fake_login(@user)
    do_request('0')
    expect(assigns(:attempt)).to eq(@attempt)
  end

  context 'with non-zero section_id,' do
    before do
      @section = build_stubbed(:section, course: build_stubbed(:course))
      allow(@user).to receive(:closed?).and_return(false)
      allow(@activity).to receive(:read_only=).and_return nil
      allow(Section).to receive(:find).and_return(@section)
      allow(@classwork).to receive(:current_workset).and_return(nil)
      ensure_correct_section(@section)
    end

    it 'assigns the course' do
      fake_login(@user)
      allow(controller).to receive(:current_section).and_return(@section)
      do_request(@section.id)
      expect(assigns(:course)).to eq(@section.course)
    end

    it 'assigns the read_only status of the activity' do
      fake_login(@user)
      allow(@user).to receive(:closed?).and_return(false)
      expect(@activity).to receive(:read_only=).with(false)
      do_request(@section.id)
    end

    it 'assigns a starting time' do
      attempt = build_stubbed(:attempt)
      allow(attempt).to receive(:attempted_version).and_return(@activity)
      allow(attempt).to receive(:activity=)
      allow(@classwork).to receive(:find_or_new_attempt).with(@activity).and_return(attempt)
      fake_login(@user)
      do_request(@section.id)
      expect(assigns(:start_time)).not_to be_nil
    end

    context 'with an existing attempt' do
      def do_request
        fake_login(@user)
        get :show, params: { id: '37', section_id: @section.id }
      end

      before do
        results = MaestroActivityEngine::ActivityContent::Results.new
        @attempt = double(Attempt, submitted_values?: true,
                                   saved_values?: false,
                                   complete?: false,
                                   offset_bytes: 0,
                                   record_length: 100,
                                   save_offset_bytes: 100,
                                   save_record_length: 100,
                                   results: results,
                                   cms_revision_id: 222,
                                   id: 123456)
        allow(@attempt).to receive(:current_view).and_return(:show)
        allow(presenter).to receive(:find_or_create_attempt).and_return(@attempt)

        @section = build_stubbed(:section, course: build_stubbed(:course))
        allow(@user).to receive(:closed?).and_return(false)
        allow(@activity).to receive(:read_only=).with(false)
        allow(controller).to receive(:current_user).and_return(@user)
        allow(Section).to receive(:find).and_return(@section)

        allow(@attempt).to receive(:stored_responses).and_return(Hash.new)
        allow(@attempt).to receive(:saved_responses).and_return(Hash.new)
        allow(@attempt).to receive(:attempt_number).and_return(1)
        allow(@attempt).to receive(:validate_responses).and_return('valid_results')
        allow(@attempt).to receive(:common_instructor_feedback).and_return(nil)
        allow(@attempt).to receive(:dismiss_pending_notifications).and_return(nil)
        allow(@attempt).to receive(:attempted?).and_return(false)
        allow(@attempt).to receive(:activity=)

        @attempt_track = mock_attempt_track(number: 2, used: 1)
        allow(AttemptTrack).to receive(:new).and_return(@attempt_track)
        allow(@attempt).to receive(:attempt_track).and_return(@attempt_track)
      end

      it 'asks attempt for the current view' do
        expect(@attempt).to receive(:current_view).and_return(:show)
        do_request
      end

      it 'assigns @attempt_track' do
        allow(@attempt).to receive(:complete?).and_return(false)
        #@results.stub(:complete?).and_return(false)
        allow(@attempt).to receive(:attempt_track).and_return(@attempt_track)
        allow(@attempt_track).to receive(:complete=).and_return(false)

        do_request
        expect(assigns(:attempt_track)).to eq(@attempt_track)
      end

      it 'renders the template suggested by the attempt' do
        allow(@attempt).to receive(:current_view).and_return(:complete)
        do_request
        expect(response).to render_template(:complete)
      end

      it 'assigns the activity return link' do
        session[:activity_return] = { 'label' => 'Somewhere', 'url' => '/valid/path' }
        do_request
        expect(assigns(:return_label)).to eq('Somewhere')
        expect(assigns(:return_url)).to eq('/valid/path')
      end
    end

    it 'assigns a starting time' do
      attempt = build_stubbed(:attempt)
      allow(attempt).to receive(:attempted?).and_return(false)
      allow(attempt).to receive(:attempted_version).and_return(@activity)
      allow(attempt).to receive(:activity=)
      allow(attempt).to receive(:activity).and_return(@activity)
      allow(@classwork).to receive(:find_or_new_attempt).with(@activity).and_return(attempt)
      fake_login(@user)
      get :show, params: { id: '37', section_id: '0' }
      expect(assigns(:start_time)).not_to be_nil
    end
  end

  context 'with no attempt record,' do
    def do_request
      fake_login(@user)
      get :show, params: { id: '37', section_id: @section.id }
    end

    before do
      allow(@classwork).to receive(:current_workset).and_return(nil)
      allow(@classwork).to receive(:closed_section?).and_return(false)
      @section = build_stubbed(:section, course: build_stubbed(:course))
      allow(@user).to receive(:closed?).and_return(false)
      allow(@activity).to receive(:read_only=).with(false)
      allow(@activity).to receive(:vtext_link=)
      allow(controller).to receive(:current_user).and_return(@user)
      allow(Section).to receive(:find).and_return(@section)
      @attempt = build_stubbed(:attempt)
      allow(@attempt).to receive(:attempted_version).and_return(@activity)
      allow(presenter).to receive(:find_or_create_attempt).and_return(@attempt)
      @attempt_track = mock_attempt_track(final: true, remaining: 0)
      allow(@attempt).to receive(:attempt_track).and_return(@attempt_track)
      allow(@attempt).to receive(:activity=)
    end

    it 'checks the max attempts' do
      expect(@attempt_track).to receive(:max).and_return('unlimited')
      @section = build_stubbed(:section, course: build_stubbed(:course))
      do_request
    end

    context 'when max attempts is 0,' do
      before do
        allow(@attempt_track).to receive(:max).and_return(0)
      end

      it 'creates a new completed attempt if section is active' do
        expect(@classwork).to receive(:ensure_completed_attempt).with(@activity)
        do_request
      end

      it 'does not mark activity as complete if section is closed' do
        allow(@classwork).to receive(:closed_section?).and_return(true)
        expect(@classwork).not_to receive(:ensure_completed_attempt).with(@activity)
        do_request
      end
    end

    it 'assigns @attempt_track' do
      allow(@attempt).to receive(:complete?).and_return(false)
      #@results.stub(:complete?).and_return(false)
      @attempt_track = mock_attempt_track()
      allow(AttemptTrack).to receive(:new).and_return(@attempt_track)
      allow(@attempt_track).to receive(:complete=).and_return(false)
      allow(@attempt_track).to receive(:practice=).and_return(false)
      allow(@attempt).to receive(:attempt_track).and_return(@attempt_track)
      allow(@attempt).to receive(:attempted_version).and_return(@activity)

      do_request
      expect(assigns(:attempt_track)).to eq(@attempt_track)
    end

    it 'assigns a starting time' do
      attempt = build_stubbed(:attempt)
      allow(attempt).to receive(:attempted_version).and_return(@activity)
      allow(attempt).to receive(:activity=)
      allow(@classwork).to receive(:find_or_new_attempt).with(@activity).and_return(attempt)
      fake_login(@user)
      get :show, params: { id: '37', section_id: '0' }
      expect(assigns(:start_time)).not_to be_nil
    end
  end

  context 'on the final attempt' do
    def do_request
      fake_login(@user)
      get :show, params: { id: '37', section_id: @section.id }
    end

    before do
      allow(@classwork).to receive(:current_workset).and_return(nil)
      allow(@classwork).to receive(:closed_section?).and_return(false)
      @section = build_stubbed(:section, course: build_stubbed(:course))
      allow(@activity).to receive(:read_only=).with(false)
      allow(controller).to receive(:current_user).and_return(@user)
      allow(Section).to receive(:find).and_return(@section)
      attempt = build_stubbed(:attempt)
      allow(attempt).to receive(:attempted_version).and_return(@activity)
      allow(presenter).to receive(:find_or_create_attempt).and_return(attempt)
      allow(attempt).to receive(:activity=)
    end

    it 'should tag the attempt as final' do
      @attempt_track = mock_attempt_track(max: 1, final: true, remaining: '1')
      allow(AttemptTrack).to receive(:new).and_return(@attempt_track)
      allow(@attempt_track).to receive(:complete=).and_return(false)
      allow(@attempt_track).to receive(:practice=).and_return(false)
      allow(@attempt_track).to receive(:attempt_number=)

      do_request
      expect(@attempt_track.final).to be_truthy
    end

    it 'assigns the activity return link' do
      session[:activity_return] = { 'label' => 'Somewhere', 'url' => '/valid/path' }
      do_request
      expect(assigns(:return_label)).to eq('Somewhere')
      expect(assigns(:return_url)).to eq('/valid/path')
    end
  end

  context 'attempt complete and no results' do
    def do_request
      fake_login(@user)
      get :show, params: { id: '37', section_id: @section.id }
    end

    before do
      allow(@classwork).to receive(:current_workset).and_return(nil)
      allow(@classwork).to receive(:closed_section?).and_return(false)
      @section = build_stubbed(:section, course: build_stubbed(:course))
      allow(@activity).to receive(:read_only=).with(false)
      allow(controller).to receive(:current_user).and_return(@user)
      allow(Section).to receive(:find).and_return(@section)
      attempt = build_stubbed(:attempt)
      allow(attempt).to receive(:attempted_version).and_return(@activity)
      allow(attempt).to receive(:current_view).and_return(:complete)
      allow(attempt).to receive(:results).and_return(nil)
      allow(presenter).to receive(:find_or_create_attempt).and_return(attempt)
      allow(attempt).to receive(:activity=)
      session[:activity_return] = { 'label' => 'Somewhere', 'url' => '/valid/path' }
      allow(VHLMonitor).to receive(:notify)
    end
    it 'should set flash error msg' do
      msg = "We're sorry. The results for this activity are unavailable.
              Need access to these results?
              Contact technical support at ts@vistahigherlearning.com."

      do_request
      expect(flash[:error]).to eq(msg)
    end

    it 'should redirect to the return_url ' do
      do_request
      expect(response).to redirect_to('/valid/path')
    end

    it 'should log a Rollbar error' do
      expect(VHLMonitor).to receive(:notify)
      do_request
    end
  end

  context 'when an unsubmitted activity is adjusted' do
    def do_request
      fake_login(@user)
      get :show, params: { id: '37', section_id: @section.id }
    end

    before do
      allow(controller).to receive(:require_program_access).and_return(true)
      allow(controller).to receive(:require_component_privileges).and_return(true)
      allow(@classwork).to receive(:current_workset).and_return(nil)
      allow(@classwork).to receive(:closed_section?).and_return(false)
      @section = build_stubbed(:section, course: build_stubbed(:course))
      allow(Section).to receive(:find).and_return(@section)
      allow(Section).to receive(:find_by_id).and_return(@section)
      allow(@activity).to receive(:read_only=).with(false)
      allow(controller).to receive(:current_user).and_return(@user)
      # allow(controller).to receive(:current_section).and_return(@section)
      # allow(controller).to receive(:current_section_id).and_return(@section.id.to_s)
      allow(@user).to receive(:current_section_in_program).and_return(@section)
      allow(@user).to receive(:sufficient_access_for_course?).and_return(true)
      attempt = build_stubbed(:attempt)
      allow(attempt).to receive(:attempted_version).and_return(@activity)
      allow(@classwork).to receive(:find_or_new_attempt).and_return(attempt)

      student_grade = instance_double(GradebookEngine::AssignmentGrade,
                                      submitted?: false,
                                      adjusted?: true)
      allow(GradebookEngine::GradebookAPI).to receive(:find_student_grade)
        .and_return(student_grade)
      ensure_correct_section(@section)
    end
  end

  context 'when is a no-section student' do
    let(:section) { build_stubbed(:section_with_course) }

    before do
      skip
      allow(@controller).to receive(:current_section)
      allow(@user).to receive(:current_section_in_program)
    end

    def do_request(params = {})
      fake_login(@user)
      get :show, params: { id: '37', section_id: section.id }.merge(params)
    end

    context 'when the specified section_id is not 0' do
      it 'redirect to the same URL but section_id = 0', test_debt: true do
        do_request(section_id: '123')
        expect(@controller).to redirect_to section_activity_path('0', '37')
      end
    end

    context 'when the specified section_id is 0' do
      it 'redirect to the same URL', test_debt: true do
        expect(@controller).not_to receive(:redirect_to)
        do_request(section_id: '0')
        expect(response).to render_template :show
      end
    end
  end

  context 'when the student have an active section' do
    let(:section) { build_stubbed(:section_with_course) }

    before do
      skip
      allow(@controller).to receive(:current_section).and_return(section)
      allow(@user).to receive(:active_sections).and_return([section])
      allow(@user).to receive(:current_section_in_program).and_return(section)
      enrollment = build_stubbed(:active_enrollment, user: @user, section: section, blocked: false)
    end

    def do_request(params = {})
      fake_login(@user)
      get :show, params: { id: '37', section_id: section.id }.merge(params)
    end

    context 'when the specified section_id is not the same' do
      it 'redirect to the same URL using student active section', test_debt: true do
        allow(@controller).to receive(:current_section).and_return(build_stubbed(:section_with_course))
        do_request
        expect(@controller).to redirect_to section_activity_path(section.id, '37')
      end
    end

    context 'when the specified section_id is the same' do
      it 'redirect to the same URL', test_debt: true do
        expect(@controller).not_to receive(:redirect_to)
        do_request(section_id: section.id)
        expect(response).to render_template :show
      end
    end
  end

  context 'when a non-zero section param for a section that does not exist is specified' do
    it 'generates a valid response' do
      non_existing_section_id = '12345'
      allow(controller).to receive(:current_section).and_return(nil)
      allow(controller).to receive(:current_user).and_return(@user)
      do_request(non_existing_section_id)
      expect(response.status).to eq(302)
    end
  end
end

shared_examples 'an action that informs the assessment is not available' do
  before do
    allow(presenter).to receive(:redirect_to_dashboard?).and_return(true)
    allow(presenter).to receive(:flash_notice).and_return('assessment not yet released.')
    ensure_correct_section(section)
  end

  it 'should display a flash message informing that the assessment is not available' do
    fake_login(@user)
    do_request(section.id)
    expect(flash[:notice]).to eq('assessment not yet released.')
  end
end

shared_examples 'an action that renders the show view' do
  context 'when the specified section param is for their active section,' do
    it 'renders the show view and does not redirect them' do
      allow(controller).to receive(:current_section).and_return(active_section)
      fake_login(@user)
      do_request
      expect(response.redirect_url).to be_nil
      expect(response).to render_template :show
    end
  end
end

shared_examples 'an action that sets up an assignment validator' do
  it 'sets up an assignment validator' do
    fake_login(user)
    allow(@controller).to receive(:require_program_access).and_return(true)
    get :show, params: { id: 1, section_id: 2 }
    expect(assigns(:assignment_validator)).to be_a(AssignmentValidator)
  end
end

shared_examples 'an action that allows to re-try the activity' do
  let(:school) { build_stubbed(:school) }
  before do
    @program = build_stubbed(:program)
    @strand = build_stubbed(:toc_entry)
    @lesson = build_stubbed(:lesson, unit: build_stubbed(:unit, program: @program))
    allow(Lesson).to receive(:find).with(@lesson.id).and_return(@lesson)
    allow(@lesson).to receive(:strand_for_toc_location).and_return(@strand)
    allow(@lesson).to receive(:substrand_for_toc_location).and_return(@strand)
    allow(@lesson).to receive(:display_name).and_return('Lesson 1')
    @activity = create(:activity, id: 55,
                                  cms_revision_id: 1,
                                  read_only: nil,
                                  toc_location: @strand.id,
                                  lesson: @lesson)
    allow(@activity).to receive(:content_object).and_return(mock_content_object)
    allow(@activity).to receive(:program).and_return(@program)
    allow(@activity).to receive(:list_header).and_return('lesson foo / strand bar')
    allow(@activity).to receive(:assessment?).and_return(false)
    allow(@activity).to receive(:content_object).and_return(mock_content_object)
    allow(@activity.content_object).to receive(:external_references).and_return([])
    allow(@activity).to receive(:ensure_correct_version)
    allow(@activity).to receive(:content_summary).and_return(test_content_summary: 1)
    allow(scope).to receive(:find).and_return(@activity)

    @results = [{ 'label' => 'label_01', 'correctness' => 'correct', 'response' => 'correct answer' }]

    @attempt = double(Attempt, section_id: 100,
                               user_id: 10,
                               activity_id: 55,
                               offset_bytes: 0,
                               record_length: 55555,
                               time_spent: 60,
                               cms_revision_id: 222,
                               complete?: false,
                               submission_length: 123,
                               propagate_time_spent_to_score: true)
    allow(@attempt).to receive(:attempt_number).and_return(1)
    allow(@attempt).to receive(:attempt_track).and_return(nil)
    allow(@attempt).to receive(:scoring_ruleset=)
    allow(@attempt).to receive(:activity=)

    allow(@attempt).to receive(:last_possible?).and_return(false)

    allow(@classwork).to receive(:find_or_new_attempt).and_return(@attempt)
    allow(@classwork).to receive(:current_workset)
    allow(@classwork).to receive(:current_scoring_ruleset).and_return(ScoringRuleset.default)
    allow(@classwork).to receive(:find_active_attempt).and_return(@attempt)

    allow(@attempt).to receive(:set_attempt).and_return(true)
    allow(@attempt).to receive(:validate_responses).and_return(@results)
    allow(@attempt).to receive(:write_results)
    allow(@attempt).to receive(:add_time_spent)

    @start_time = Time.now.utc.to_i
    @end_time = @start_time + 90
    allow(@controller).to receive(:time_now_in_seconds).and_return(@end_time)
    @time_spent = 90

    @section = create(
      :section,
      id: 1,
      course: build_stubbed(:course, school: school)
    )
    allow(Section).to receive(:find_by_id).and_return(@section)
    @section_id = @section.id

    @submission = double(Gradebook::Submission)
    allow(@submission).to receive(:submit).and_return(score)
    allow(Gradebook::Submission).to receive(:new).and_return(@submission)
    allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
  end

  context 'when student is re-trying the activity' do
    before do
      allow(@results).to receive(:complete?).and_return(false)
      allow(@attempt).to receive(:validate_responses).and_return(double('Results', complete?: false))
      allow(@attempt).to receive(:results).and_return(Hash.new)
      allow(@attempt).to receive(:propagate_time_spent_to_score)
      allow_any_instance_of(Section).to receive(:school).and_return(build_stubbed(:school))
      fake_login(@user)
    end

    it 'renders submit' do
      post :re_try, params: { id: '55', section_id: '0', question_01: 'right answer' }
      expect(response).to render_template(:submit)
    end

    it 'updates time spent for the attempt record' do
      post :re_try, params: { id: '55', section_id: '0', question_01: 'right answer' }
      expect(@attempt).to have_received(:add_time_spent)
    end

    it 'propagates the time spent update to the score' do
      post :re_try, params: { id: '55', section_id: @section.id }
      expect(@attempt).to have_received(:propagate_time_spent_to_score)
    end
  end
end

shared_examples 'an action that submits an activity' do
  before do
    allow(controller).to receive(:assign_section_header)
    @program = build_stubbed(:program)
    @strand = build_stubbed(:toc_entry)
    @lesson = build_stubbed(:lesson)
    allow(@lesson).to receive(:strand_for_toc_location).and_return(@strand)
    allow(@lesson).to receive(:substrand_for_toc_location).and_return(@strand)
    allow(@lesson).to receive(:display_name).and_return('Lesson 1')
    @activity = create(:activity, id: 55,
                                  cms_revision_id: 1,
                                  read_only: nil,
                                  toc_location: @strand.id,
                                  lesson: @lesson)
    allow(@activity).to receive(:content_object).and_return(mock_content_object)
    allow(@activity).to receive(:program).and_return(@program)
    allow(@activity).to receive(:list_header).and_return('lesson foo / strand bar')
    allow(@activity).to receive(:assessment?).and_return(false)
    allow(@activity).to receive(:content_object).and_return(mock_content_object)
    allow(@activity.content_object).to receive(:external_references).and_return([])
    allow(@activity).to receive(:ensure_correct_version)
    allow(@activity).to receive(:content_summary).and_return(test_content_summary: 1)
    allow(scope).to receive(:find).and_return(@activity)

    @results = [{ 'label' => 'label_01', 'correctness' => 'correct', 'response' => 'correct answer' }]

    @attempt = double(Attempt, section_id: 100,
                               user_id: 10,
                               activity_id: 55,
                               offset_bytes: 0,
                               record_length: 55555,
                               time_spent: 60,
                               cms_revision_id: 222,
                               complete?: false,
                               submission_length: 123)
    allow(@attempt).to receive(:attempt_number).and_return(1)
    allow(@attempt).to receive(:attempt_track).and_return(nil)
    allow(@attempt).to receive(:scoring_ruleset=)
    allow(@attempt).to receive(:activity=)

    allow(@attempt).to receive(:last_possible?).and_return(false)

    allow(@classwork).to receive(:find_or_new_attempt).and_return(@attempt)
    allow(@classwork).to receive(:current_workset)
    allow(@classwork).to receive(:current_scoring_ruleset).and_return(ScoringRuleset.default)
    allow(@classwork).to receive(:find_active_attempt).and_return(@attempt)

    allow(@attempt).to receive(:set_attempt).and_return(true)
    allow(@attempt).to receive(:validate_responses).and_return(@results)
    allow(@attempt).to receive(:write_results)

    @start_time = Time.now.utc.to_i
    @end_time = @start_time + 90
    allow(@controller).to receive(:time_now_in_seconds).and_return(@end_time)
    @time_spent = 90

    @section = create(:section, id: 1, course: build_stubbed(:course))
    allow(Section).to receive(:find_by_id).and_return(@section)
    @section_id = @section.id

    @submission = double(Gradebook::Submission)
    allow(@submission).to receive(:submit).and_return(score)
    allow(Gradebook::Submission).to receive(:new).and_return(@submission)
    allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
  end

  it_behaves_like 'an action that finds and assigns activity by id'
  it_behaves_like 'an action that assigns an activity presenter' do
    before do
      allow(@user).to receive(:instructor?).and_return(false)
    end
  end
  it_behaves_like 'an action that assigns video settings from the presenter'
  it_behaves_like 'an action that handles timespent error cases'

  context 'for non-js submits,' do
    before do
      fake_login(@user)
    end

    context "when commit is 'Re-try'" do
      it 'calls the re_try action' do
        expect(controller).to receive(:re_try)
        post :submit, params: { commit: 'Re-try', id: '55', section_id: '1', question_01: 'right answer', start_time: @start_time }
      end
    end

    context "when commit is 'Accept'" do
      it 'calls the finalize action' do
        expect(controller).to receive(:finalize)
        post :submit, params: { commit: 'Accept', id: '55', section_id: '1', question_01: 'right answer', start_time: @start_time }
      end
    end
  end

  context 'with unstubbed section header,' do
    it_should_assign_section_header do
      allow(controller).to receive(:assign_section_header).and_call_original
      allow(@attempt).to receive(:complete?).and_return(true)
      allow(@attempt).to receive(:stored_responses).and_return({})
      get :submit, params: { id: '37', section_id: '1' }
    end
  end

  def do_request(params ={})
    fake_login(@user)
    allow(@results).to receive(:complete?).and_return(false)
    allow(@attempt).to receive(:user).and_return(@user)
    post :submit, params: { id: '55', section_id: '1', question_01: 'right answer', start_time: @start_time }.merge(params)
  end

  context 'for uploader' do
    before do
      fake_login(@user)
    end

    it_should_behave_like 'an action that assigns allowed file extensions'
  end

  it 'finds or creates an attempt record' do
    allow(@attempt).to receive(:complete?).and_return(false)
    allow(@attempt).to receive(:time_spent).and_return(90)
    allow(@attempt).to receive(:submission_length).and_return(nil)
    expect(@submission).to receive(:submit).with(@results, anything, @time_spent, nil)
    do_request
    expect(assigns(:attempt)).to eq(@attempt)
  end

  it 'finds or creates a score record' do
    allow(@attempt).to receive(:complete?).and_return(false)
    allow(@attempt).to receive(:submission_length).and_return(nil)
    expect(@classwork).to receive(:find_or_new_attempt).with(@activity).and_return(@attempt)
    do_request
    expect(assigns(:attempt)).to eq(@attempt)
  end

  it 'assigns @attempt_track' do
    allow(@attempt).to receive(:complete?).and_return(false)
    allow(@attempt).to receive(:submission_length).and_return(nil)
    allow(@results).to receive(:complete?).and_return(false)
    @attempt_track = mock_attempt_track(number: 2, used: 1)
    allow(@attempt).to receive(:attempt_track).and_return(@attempt_track)
    allow(@attempt_track).to receive(:complete=).and_return(false)
    allow(@attempt).to receive(:attempt_track).and_return(@attempt_track)

    do_request
    expect(assigns(:attempt_track)).to eq(@attempt_track)
  end

  it 'assigns @attempt' do
    allow(@attempt).to receive(:complete?).and_return(false)
    allow(@attempt).to receive(:submission_length).and_return(nil)
    do_request
    expect(assigns(:attempt)).to eq(@attempt)
  end

  context 'when saving recordings' do
    let(:recording_saver) { double('RecordingSaver') }

    it 'creates recordings records' do
      expect(RecordingSaver).to receive(:new).with(@activity, @user, @results).and_return(recording_saver)
      expect(recording_saver).to receive(:save_recordings)
      do_request
    end
  end


  context 'when the attempt is not already marked as complete,' do
    before do
      allow(@classwork).to receive(:current_workset).and_return(nil)

      allow(@attempt).to receive(:complete?).and_return(false)
      allow(@attempt).to receive(:submission_length).and_return(nil)
      allow(@attempt).to receive(:validate_responses).and_return(@results)
      allow(@attempt).to receive(:validate_responses).and_return('valid_results')
      allow(@attempt).to receive(:last_possible?).and_return(true)
      allow(@attempt).to receive(:add_time_spent)
      allow(@attempt).to receive(:mark_as_completed)
      allow(@attempt).to receive(:results).and_return({})
      allow(@classwork).to receive(:find_active_attempt).and_return(@attempt)
    end

    it 'validates responses and assigns to @results' do
      expect(@attempt).to receive(:validate_responses).and_return('valid_results')
      do_request
      expect(assigns(:results)).to eq('valid_results')
    end

    it "saves the student's responses" do
      expect(@attempt).to receive(:write_results).with('valid_results', true, 'submitted', @start_time, @end_time)
      do_request
    end

    context 'when the current attempt is max attempts,' do
      before do
        expect(@attempt).to receive(:last_possible?).and_return(true)
      end

      it 'renders complete' do
        do_request

        expect(response).to render_template(:complete)
      end
    end

    context 'when current attempt is all questions are answered completely,' do
      before do
        allow(@attempt).to receive(:last_possible?).and_return(false)
        allow(@attempt).to receive(:validate_responses).and_return(double('Results', complete?: true))
      end

      it 'renders complete' do
        do_request

        expect(response).to render_template(:complete)
      end
    end

    context 'when attempt is not completed,' do
      before do
        allow(@attempt).to receive(:last_possible?).and_return(false)
        allow(@attempt).to receive(:validate_responses).and_return(double('Results', complete?: false))
      end

      it 'renders decide' do
        do_request

        expect(response).to render_template(:decide)
      end
    end
  end

  context 'when the required response format is json' do
    let(:activity_builder) { double('activity_response_builder') }
    let(:sample_response) do
      { test_key: 'json data' }.to_json
    end
    let(:sample_status) { :ok }

    before do
      allow(@attempt).to receive(:last_possible?).and_return(true)
      allow(activity_builder).to receive(:to_json).and_return(sample_response)
      allow(activity_builder).to receive(:status).and_return(sample_status)
    end

    it 'creates a activity response builder' do
      expect(ActivityResponseBuilder).to receive(:new).and_return(activity_builder)
      do_request(format: 'json')
    end

    it 'renders json data' do
      allow(ActivityResponseBuilder).to receive(:new).and_return(activity_builder)
      json_params = { json: sample_response, status: sample_status }
      do_request(format: 'json')
      expect(response).to be_successful
      expect(response.body).to eq sample_response
    end
  end
end

shared_examples 'an action that validates attempt' do
  before do
    allow(@classwork).to receive(:current_workset).and_return(nil)
    allow(@attempt).to receive(:complete?).and_return(true)
    allow(@attempt).to receive(:validate_responses).and_return(@results)
  end

  it 'reads the responses from xml, validates, and assigns to @results' do
    expected_params = { 'id' => '55', 'section_id' => @section_id.to_s }
    expected_params.merge!('valid' => 'params')
    allow(@attempt).to receive(:stored_responses).and_return('valid' => 'params')
    expect(@attempt)
      .to receive(:validate_responses)
      .with(@activity, hash_including(expected_params), anything)
      .and_return(@results)
    do_request
    expect(assigns(:results)).to eq(@results)
  end

  it 'renders the completed view' do
    allow(@attempt).to receive(:stored_responses).and_return(Hash.new)
    do_request
    expect(response).to render_template(:complete)
  end
end

shared_examples 'an action that start practice mode' do
  before do
    @program = build_stubbed(:program)
    @strand = build_stubbed(:toc_entry)
    @lesson = build_stubbed(:lesson)
    allow(@lesson).to receive(:strand_for_toc_location).and_return(@strand)
    allow(@lesson).to receive(:substrand_for_toc_location).and_return(@strand)
    allow(@lesson).to receive(:display_name).and_return('Lesson 1')
    @activity = instance_double(
      Activity,
      activity_type: 'fill_in_the_blanks',
      ai_virtual_chat?: false,
      cms_activity_id: 10,
      cms_revision_id: 11,
      content_object: mock_content_object,
      id: 55,
      title: 'A Doubled Activity',
      lesson: @lesson,
      listed?: false,
      partner_chat?: false,
      group_chat?: false,
      question_bank?: false,
      santillana?: false,
      program: @program,
      toc_location: @strand.id,
      :read_only= => nil
    )
    allow(@activity).to receive(:list_header).and_return('lesson foo / strand bar')
    allow(@activity).to receive(:assessment?).and_return(false)
    allow(@activity.content_object).to receive(:external_references).and_return([])
    allow(@activity).to receive(:content_summary).and_return(test_content_summary: 1)
    allow(@activity).to receive(:vtext_link=)
    allow(scope).to receive(:find).and_return(@activity)

    @results = double('MaestroActivityEngine::ActivityContent::Results')
    allow(@results).to receive(:results).and_return([{ 'label' => 'label_01', 'correctness' => 'correct', 'response' => 'correct answer' }])
    allow(@results).to receive(:complete?).and_return(false)

    @attempt = double(Attempt, section_id: 100, user_id: 10, activity_id: 55, offset_bytes: 0, record_length: 0)
    allow(@attempt).to receive(:attempt_number).and_return(1)
    allow(@attempt).to receive(:attempt_track).and_return(nil)
    allow(@attempt).to receive(:practice_complete=).and_return(false)
    allow(@attempt).to receive(:practice_complete?).and_return(false)
    allow(@attempt).to receive(:status_code=).and_return(true)
    allow(@attempt).to receive(:updated_at=).and_return(true)
    allow(@attempt).to receive(:activity=)

    allow(@classwork).to receive(:practice_attempt).and_return(@attempt)
    allow(@classwork).to receive(:current_workset)
    allow(@attempt).to receive(:set_attempt).and_return(true)

    allow(@attempt).to receive(:validate_responses).and_return(@results)
    @section_id = '0'
    allow(@attempt).to receive(:practice=).and_return(false)
    allow(@attempt).to receive(:user).and_return(@user)
    allow(controller.instance_eval { flash }).to receive(:sweep)
    allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
  end

  context 'when entering practice mode' do
    before do
      allow(@results).to receive(:complete?).and_return(false)
      fake_login(@user)
    end

    def do_request
      get :practice, params: { id: '55', section_id: '0' }
    end

    it_behaves_like 'an action that assigns an activity presenter' do
      before do
        allow(@user).to receive(:instructor?).and_return(false)
      end
    end
    it_behaves_like 'an action that assigns video settings from the presenter'

    it 'should display a practice flash notice' do
      do_request
      expect(flash[:notice]).to eq('Practice mode. Answers will not be saved!')
    end

    it 'should render the show view' do
      do_request
      expect(response).to render_template(:show)
    end

    it 'should set unlocked assessments on the session if not set' do
      session[:unlocked_assessments] = nil
      do_request
      expect(session[:unlocked_assessments]).to eq([])
    end
  end

  def do_practice
    fake_login(@user)
    get :practice, params: { id: '55', section_id: '0', commit: 'Check' }
  end

  context 'when submitting in practice mode' do
    def do_request
      do_practice
    end

    it_behaves_like 'an action that assigns an activity presenter' do
      before do
        allow(@user).to receive(:instructor?).and_return(false)
      end
    end
    it_behaves_like 'an action that assigns video settings from the presenter'

    it 'should display a practice flash notice' do
      allow(@results).to receive(:complete?).and_return(false)
      do_practice
      expect(flash[:notice]).to eq('Practice mode. Answers will not be saved!')
    end

    it 'should display the submit view' do
      allow(@results).to receive(:complete?).and_return(false)
      do_practice
      expect(response).to render_template(:submit)
    end

    it 'should display the complete view if all answers are correct' do
      results = double('MaestroActivityEngine::ActivityContent::Results')
      allow(results).to receive(:results).and_return([{ 'label' => 'label_01', 'correctness' => 'correct', 'response' => 'correct answer' }])
      allow(results).to receive(:complete?).and_return(true)
      allow(@attempt).to receive(:validate_responses).and_return(results)
      allow(@attempt).to receive(:practice_complete?).and_return(true)
      allow(@attempt).to receive(:status_code=).and_return(true)
      allow(@attempt).to receive(:updated_at=).and_return(true)
      do_practice
      expect(response).to render_template(:complete)
    end
  end

  def do_answers
    allow(@attempt).to receive(:practice_complete?).and_return(true)
    allow(@attempt).to receive(:user).and_return(@user)
    fake_login(@user)
    post :practice, params: { id: '55', section_id: '0', commit: 'Answers' }
  end

  context 'when asking for the answers' do
    def do_request
      do_answers
    end

    it_behaves_like 'an action that assigns an activity presenter' do
      before do
        allow(@user).to receive(:instructor?).and_return(false)
      end
    end
    it_behaves_like 'an action that assigns video settings from the presenter'

    it 'should display a view answers flash notice' do
      allow(@results).to receive(:complete?).and_return(false)
      allow(@attempt).to receive(:status_code=).and_return(true)
      allow(@attempt).to receive(:updated_at=).and_return(true)
      do_answers
      expect(flash[:notice]).to eq('Viewing answers.')
    end

    it 'should display the complete view' do
      results = double('MaestroActivityEngine::ActivityContent::Results')
      allow(results).to receive(:results).and_return([{ 'label' => 'label_01', 'correctness' => 'correct', 'response' => 'correct answer' }])
      allow(results).to receive(:complete?).and_return(false)
      allow(@attempt).to receive(:validate_responses).and_return(results)
      allow(@attempt).to receive(:practice_complete?).and_return(true)
      allow(@attempt).to receive(:status_code=).and_return(true)
      allow(@attempt).to receive(:updated_at=).and_return(true)
      do_answers
      expect(response).to render_template(:complete)
    end
  end
end

shared_examples 'an action that shows answer key' do
  let(:program) { build_stubbed(:program) }
  let(:course) { build_stubbed(:course) }
  let(:section) { build_stubbed(:section, id: 0, course: course) }
  let(:activity) do
    double(
      'Activity',
      id: 55,
      program: program,
      lesson: double(Lesson),
      partner_chat?: false,
      group_chat?: false,
      question_bank?: false,
      title: 'A Doubled Activity',
      listed?: false,
      assessment?: false
    )
  end
  let(:attempt) { double('attempt') }
  let(:classwork) { double('classwork') }
  let(:presenter) do
    double('StudentActivityPresenter', activity: @activity,
                                       activity_list_header: 'Leccion 1 | Adelante | Lectura',
                                       lesson_header: 'Leccion 1',
                                       notifications: [])
  end
  before do
    allow(scope).to receive(:find).and_return(activity)
    allow(Activity).to receive(:latest).and_return(activity)
    allow(controller).to receive(:common_prep)
    allow(controller.instance_eval { flash }).to receive(:sweep)
    allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
    allow(Attempt).to receive(:new).and_return(attempt)
    session[:activity_return] = { 'label' => 'Somewhere', 'url' => '/valid/path' }
    fake_login(instructor)
    allow(instructor).to receive(:has_current_access_to?).and_return(true)
    allow(presenter.notifications).to receive(:dismiss_all!)
    controller.instance_variable_set(:@transcript_settings, MaestroActivityEngine::TranscriptSettings.new)
  end

  def do_request
    get :answer_keys, params: { id: '55', section_id: '0' }
  end

  it 'displays the appropiate flash notice' do
    do_request
    expect(flash[:notice]).to eq('Answer key mode. All correct answers will be displayed')
  end

  it 'renders the answer keys view' do
    do_request
    expect(response).to render_template(:answer_keys)
  end

  it 'uses the activity layout' do
    do_request
    expect(response).to render_template('layouts/activity')
  end

  it 'instanciates a new StudentActivityPresenter' do
    expect(StudentActivityPresenter).to receive(:new).and_return(presenter)
    do_request
  end

  it 'assigns the activity return link' do
    do_request
    expect(assigns(:return_label)).to eq('Somewhere')
    expect(assigns(:return_url)).to eq('/valid/path')
  end

  it 'allows instructors to see transcripts for an audio activity' do
    do_request

    expect(assigns(:transcript_settings).show_transcripts).to be true
  end
end

shared_examples 'an action to finalize the activity' do
  let(:school) { build_stubbed(:school) }
  before do
    @program = build_stubbed(:program)
    @activity = create(:activity, id: 55,
                                  cms_revision_id: 90000055,
                                  lesson: create(:lesson, unit: create(:unit)))
    allow(@activity).to receive(:read_only=)
    allow(@activity).to receive(:assessment?).and_return(false)
    allow(@activity).to receive(:content_summary).and_return(test_content_summary: 1)
    allow(@activity).to receive(:ensure_correct_version)
    allow(@activity).to receive(:content_object).and_return(mock_content_object)
    allow(@activity).to receive(:program).and_return(@program)
    %i(composition? partner_chat? group_chat? listed?).each do |method|
      allow(@activity).to receive(method).and_return(false)
    end
    allow(@activity).to receive(:vtext_link=)

    allow(@classwork).to receive(:current_workset)
    @results = double('MaestroActivityEngine::ActivityContent::Results')

    @attempt = build_stubbed(:attempt)
    allow(@attempt).to receive(:save).and_return(true)
    allow(@attempt).to receive(:attempt_number).and_return(1)
    allow(@attempt).to receive(:add_time_spent)
    allow(@attempt).to receive(:propagate_time_spent_to_score)
    allow(@attempt).to receive(:mark_as_completed).and_return(true)
    allow(@attempt).to receive(:time_spent).and_return(@time_spent)
    allow(@attempt).to receive(:cms_revision_id)
    allow(@attempt).to receive(:activity=)
    allow(@attempt).to receive(:activity).and_return(@activity)

    allow_any_instance_of(::Gradebook::Submission).to receive(:update_new_gradebook)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
  end

  def do_request(local_params = {})
    allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
    allow(scope).to receive(:find).and_return(@activity)
    allow(@classwork).to receive(:find_active_attempt).and_return(@attempt)
    fake_login(@user)
    new_params = { id: '55', section_id: '0' }.merge(local_params)
    post :finalize, params: new_params
  end

  it_behaves_like 'an action that finds and assigns activity by id'
  it_behaves_like 'an action that assigns an activity presenter' do
    before do
      allow(@user).to receive(:instructor?).and_return(false)
    end
  end
  it_behaves_like 'an action that assigns video settings from the presenter'

  context 'when student is finalizing the activity' do
    before do
      allow(@results).to receive(:complete?).and_return(false)
      allow(@attempt).to receive(:validate_responses).and_return(double('Results', complete?: false))
      allow(@attempt).to receive(:results).and_return(Hash.new)
    end

    it 'marks the attempt as completed' do
      Timecop.freeze(Time.local(2015, 10, 27, 5, 15)) do
        start_time = 1.minute.ago.to_i
        end_time = Time.now
        do_request(question_01: 'right answer', start_time: start_time)
        expect(@attempt).to have_received(:mark_as_completed)
          .with(start_time, end_time.to_i)
      end
    end

    it 'propagates the time spent update to the score' do
      start_time = 1.minute.ago.to_i
      allow(@attempt).to receive(:mark_as_completed).and_return(true)
      do_request(question_01: 'right answer', start_time: start_time)
      expect(@attempt).to have_received(:propagate_time_spent_to_score)
    end

    it 'redirects to the completed show view for the activity and current section' do
      do_request(id: '55', section_id: '0', question_01: 'right answer')
      expect(response).to redirect_to expected_path
    end
  end

  context 'when attempt exists' do
    it 'when successful, shows a flash notice' do
      do_request
      expect(flash[:notice]).to eq('Results finalized')
    end

    it 'when unsuccessful, shows a flash error' do
      expect(@attempt).to receive(:mark_as_completed).and_return(false)
      do_request
      expect(flash[:error]).to eq('Problem finalizing results')
    end

    it 're-directs to the activity show page' do
      do_request
      expect(response).to redirect_to expected_path
    end
  end

  context 'when attempt not found' do
    before do
      allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
      allow(scope).to receive(:find).and_return(@activity)
      allow(@classwork).to receive(:find_active_attempt).and_return(nil)
      allow(@classwork).to receive(:closed_section?).and_return(true)
      allow(presenter).to receive(:find_or_create_attempt).and_return(@attempt)
      allow(@attempt).to receive(:in_completed_view_without_results?).and_return(false)
      allow(@attempt).to receive(:current_view).and_return(:complete)
    end

    def do_request(local_params = {})
      fake_login(@user)
      new_params = { id: '55', section_id: '0' }.merge(local_params)
      post :finalize, params: new_params
    end

    it 'shows a flash error' do
      do_request
      expect(flash[:error]).to eq 'There was a problem recording your submission.<br/>Your instructor may have reset your work. Please re-submit to complete your assignment.'
    end

    it 'renders the template suggested by the new attempt created' do
      do_request
      expect(response).to render_template(:complete)
    end
  end

  context 'with non-zero section id' do
    before do
      allow(@classwork).to receive(:current_workset).and_return(nil)

      @course = build_stubbed(:course, school: school)
      @section = build_stubbed(:section, course: @course)
      allow(@activity).to receive(:read_only=)
      allow(@activity).to receive(:vtext_link=)
      allow(Section).to receive(:find).and_return(@section)
      allow(controller).to receive(:current_section).and_return(@section)
      allow(@attempt).to receive(:complete?).and_return(true)
      allow(@attempt).to receive(:offset_bytes).and_return(0)
      allow(@attempt).to receive(:record_length).and_return(100)
      allow(@attempt).to receive(:stored_responses).and_return(Hash.new)
      allow(@attempt).to receive(:attempt_number).and_return(1)

      allow(@classwork).to receive(:find_active_attempt).and_return(@attempt)
      allow(StudentActivityPresenter).to receive(:new).and_return(presenter)
      allow(scope).to receive(:find).and_return(@activity)

      fake_login(@user)
      do_request(section_id: @section.id)
    end

    it 'assigns the course' do
      expect(assigns(:course)).to eq(@course)
    end

    it 'assigns attempt' do
      expect(assigns(:attempt)).to eq(@attempt)
    end
  end
end

shared_examples 'an action that saves the activity' do
  let(:program) { build_stubbed(:program) }
  let(:section) { build_stubbed(:section, id: 0) }
  let(:activity) do
    double(
      'Activity',
      id: 55,
      title: 'A Doubled Activity',
      content_object: nil,
      cms_revision_id: 1,
      program: program,
      listed?: false,
      partner_chat?: false,
      group_chat?: false,
      question_bank?: false,
      composition?: :false,
      assessment?: false
    )
  end
  let(:classwork) { double(Classwork) }
  let(:activity_params) { { id: '55', section_id: section.id.to_s, question_01: 'right answer', start_time: start_time.to_s } }
  let(:attempt) { double(Attempt, cms_revision_id: 1, current_view: :show) }
  let(:start_time) { Time.now.utc.to_i }
  let(:exception) { StandardError.new('save failed') }
  let!(:saver) { ActivityWorkSaver.new(activity, attempt, activity_params, controller.request.env) }
  let(:attempt_track) { double(AttemptTrack) }

  before do
    fake_login(student)
    allow(controller).to receive(:current_user).and_return(student)
    allow(controller).to receive(:current_section).and_return(section)
    allow(controller).to receive(:time_now_in_seconds).and_return(start_time)
    allow(controller.instance_eval { flash }).to receive(:sweep)

    allow(presenter).to receive(:find_or_create_attempt)
    allow(StudentActivityPresenter).to receive(:new).and_return(presenter)

    allow(scope).to receive(:find).and_return(activity)
    allow(activity).to receive(:ai_virtual_chat?).and_return(false)
    allow(Classwork).to receive(:new).and_return(classwork)
    allow(ActivityWorkSaver).to receive(:new).and_return(saver)
    allow(activity).to receive(:ensure_correct_version)
    allow(activity).to receive(:read_only=)
    allow(activity).to receive(:vtext_link=)
    allow(student).to receive(:has_current_access_to?).and_return(true)
    allow(classwork).to receive(:find_or_new_attempt).and_return(attempt)
    allow(saver).to receive(:save).and_return(saver)
    allow(classwork).to receive(:current_workset)

    @start_time = start_time.to_i        #These two are set for shared specs
    @end_time = @start_time + 90

    allow(attempt).to receive(:activity=)
    allow(attempt).to receive(:attempt_track).and_return(attempt_track)
  end

  def do_request(params = {})
    post :save, params: activity_params.merge(params)
  end

  it_behaves_like 'an action that handles timespent error cases'

  it_should_behave_like 'an action that assigns allowed file extensions'

  context 'when there are no saving errors' do
    it 'instantiates an ActivityWorkSaver object' do
      expect(ActivityWorkSaver)
        .to receive(:new)
        .with(
          activity,
          attempt,
          hash_including(activity_params),
          controller.request.env
      )
        .and_return(saver)
      do_request
    end

    it 'calls save method on ActivityWorkSaver instance' do
      expect(saver).to receive(:save)
      do_request
    end

    it 'assigns results' do
      results = double('MaestroActivityEngine::ActivityContent::Results')
      allow(saver).to receive(:results).and_return(results)
      do_request
      expect(assigns(:results)).to eq(results)
    end

    it 'assigns attempt_track' do
      do_request
      expect(assigns(:attempt_track)).to eq(attempt_track)
    end

    it 'assigns attempt' do
      do_request
      expect(assigns(:attempt)).to eq(attempt)
    end

    it 'shows a flash message' do
      do_request
      expect(flash[:notice]).to eq('Your changes have been saved.')
    end

    it 'returns to the activity page' do
      do_request
      expect(response).to render_template(:submit)
    end
  end

  context 'when there are saving errors' do
    before do
      allow(saver).to receive(:save).and_raise(exception)
      allow(VHLMonitor).to receive(:notify)
    end

    it 'raises a Rollbar error' do
      expect(VHLMonitor).to receive(:notify)
      do_request
    end

    it 'sets an error message' do
      do_request
      expect(flash[:error]).to eq('Your work could not be saved, please try again later.')
    end

    it 'returns to the activity page' do
      do_request
      expect(response).to render_template(:show)
    end
  end
end

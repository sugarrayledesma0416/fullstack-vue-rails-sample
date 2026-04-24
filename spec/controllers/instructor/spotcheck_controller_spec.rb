describe Instructor::SpotcheckController do
  describe '#students_index' do
    let(:activity) { build_stubbed(:activity) }
    let(:activity_id) { 12_321 }
    let(:spotcheck_list) { instance_double(SpotcheckList) }

    before do
      populate_instructor_program_and_focus
      allow(Activity).to receive(:find_by_id).and_return(build_stubbed(:activity))
      allow(Activity).to receive(:find).with(activity_id.to_s).and_return(activity)
      allow(SpotcheckList).to receive(:new).and_return(spotcheck_list)
    end

    def do_request
      get :students_index, params: { program_id: @program.id, activity_id: activity_id.to_s }
    end

    it_should_have_help
    it_behaves_like 'an action that requires a logged in instructor'
    it_behaves_like 'an action that assigns program and course, sections, and students from focus'
    it_behaves_like 'an action that assigns contextual help'

    it 'is successful' do
      do_request
      expect(response).to be_successful
    end

    it 'assigns a activity id' do
      do_request
      expect(assigns(:activity_id)).to eq(activity_id.to_s)
    end

    it 'assigns a spotcheck style' do
      do_request
      expect(assigns(:spotcheck_style)).not_to be_nil
      expect(assigns(:spotcheck_style)).to eq('valid_setting')
    end

    it 'assigns a selected students count from settings' do
      do_request
      expect(assigns(:num_random_students_count)).not_to be_nil
      expect(assigns(:num_random_students_count)).to eq('valid_setting')
      expect(assigns(:num_outliers_count)).not_to be_nil
      expect(assigns(:num_outliers_count)).to eq('valid_setting')
    end

    it 'creates a SpotcheckList instance' do
      do_request
      expect(SpotcheckList).to have_received(:new)
        .with(
          activity_id: activity_id.to_s,
          section_ids: @sections.map(&:id),
          students: @students,
          unassigned: false
        )
    end

    it 'assigns the created SpotcheckList instance' do
      do_request
      expect(assigns(:spotcheck_list)).to eq(spotcheck_list)
    end

    it 'assigns the activity information' do
      do_request
      expect(Activity).to have_received(:find).with(activity_id.to_s)
      expect(assigns(:activity)).not_to be_nil
    end
  end

  describe '#update' do
    before do
      populate_instructor_program_and_focus
      @activity = build_stubbed(:activity)
      allow(Activity).to receive(:find).and_return(@activity)
      @grading_set = build_stubbed(:grading_set, activity_id: @activity.id)
      allow(@grading_set).to receive(:errors).and_return([])
      allow(@grading_set).to receive(:give_grade_to_all)
      allow(GradingSet).to receive(:find).and_return(@grading_set)
    end

    def do_request(params={})
      params.merge!(program_id: @program.id, grading_set_id: @grading_set.id.to_s)
      post :update, params: params
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'
    it_should_behave_like 'an action that assigns contextual help'

    it 'should call give grade to all if grant_grade param is set' do
      expect(@grading_set).to receive(:grade_all_full_credit).with(
        sections: @sections,
        cartridge_params: {},
        students: @students
      )
       do_request(grant_grade: '100')
    end

    context 'when success' do
      it 'set success flash' do
        allow(@grading_set).to receive(:grade_all_full_credit)
        do_request(grant_grade: '100')
        expect(flash[:notice]).to eq("Spotchecking for the activity #{@activity.title} was completed successfully.")
      end

      it "redirect to 'to_do' home" do
        do_request
        expect(response).to redirect_to(instructor_grading_tasks_assignments_path(@program.id))
      end
    end
  end

  describe '#update_style' do
    before do
      populate_instructor_program_and_focus
    end
    def do_request
      post :update_style, params: { program_id: @program.id, spotcheck_style: 'random', activity_id: '12321' }
    end

    it 'should set grading style' do
      expect(@instructor).to receive(:set).with(Setting::GradingTasks::SpotcheckStyle, 'random')
      allow(@controller).to receive(:current_user).and_return(@instructor)
      do_request
    end

    it 'should render nothing' do
      do_request
      expect(response.body).to be_blank
    end
  end

  describe '#update_style' do
    before do
      populate_instructor_program_and_focus
    end
    def do_request
      post :update_selected_students_count, params: { program_id: @program.id, select_num_of_random_students: 'All', activity_id: '12321', select_num_of_outliers: 'All' }
    end

    it 'should set selected students count' do
      expect(@instructor).to receive(:set).with(Setting::GradingTasks::SpotcheckSelectedRandomStudentsCount, 'All')
      expect(@instructor).to receive(:set).with(Setting::GradingTasks::SpotcheckSelectedOutliersCount, 'All')
      allow(@controller).to receive(:current_user).and_return(@instructor)
      do_request
    end

    it 'should render nothing' do
      do_request
      expect(response.body).to be_blank
    end
  end
end

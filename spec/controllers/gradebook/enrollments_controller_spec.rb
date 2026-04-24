describe Gradebook::EnrollmentsController do
  include GradebookHelper
  include ApplicationHelper
  def set_up_program_and_focus(params = {})
    @user = build_stubbed(:instructor)
    allow(@user).to receive(:has_current_access_to?).and_return(true)
    fake_login(@user)

    @timeframe = 'valid_setting'
    allow(@user).to receive(:setting).and_return(@timeframe)

    @program = build_stubbed(:program, maestro_version: 3)
    allow(Program).to receive(:find_by_id).and_return(@program)

    @course = params[:course] || build_stubbed(:course, program: @program)
    allow(@user).to receive(:open_courses_for_program).and_return([@course])

    @students = params[:students] || []
    @sections = params[:sections] || []

    @sort = { column: 'Name', direction: 'desc', category_id: '' }

    @category = build_stubbed(:category, id: 123)
    allow(Category).to receive(:find_by_id).and_return(@category)

    @focus = double(Focus, course: @course, sections: @sections, students: @students, type: 'foo')
    allow(Focus).to receive(:new).and_return(@focus)
  end

  describe '#edit_collection' do
    let(:course) { build_stubbed(:course) }
    let(:section_1) { build_stubbed(:section, course: course) }
    let(:section_2) { build_stubbed(:section, course: course) }
    let(:student_1) { build_stubbed(:student) }
    let(:enrollment_1) { build_stubbed(:enrollment, user: student_1, section: section_1) }
    let(:sections) { [section_1, section_2] }
    let(:droppable_students_presenter) { double(DroppableStudentsPresenter) }

    before do
      set_up_program_and_focus(students: [student_1], sections: sections)
      allow(DroppableStudentsPresenter).to receive(:new).and_return(droppable_students_presenter)
      allow(droppable_students_presenter).to receive(:droppable_students_info).and_return([])
    end

    def do_request
      default_params = { return_to: "/gradebook/#{@program.id}", program_id: @program.id }
      get :edit_collection, params: default_params
    end

    it_should_behave_like 'an action that assigns program and focus'
    it_should_behave_like 'an action that requires a logged in instructor'

    it 'should assign a return to param' do
      do_request
      expect(assigns(:return_to)).to eq("/gradebook/#{@program.id}")
    end

    it 'should find and assign information about enrollments for each student in the focus' do
      do_request
      expect(assigns[:droppable_students_presenter]).to eql(droppable_students_presenter)
    end
  end

  describe '#update_collection' do
    let(:course) { create(:course) }
    let(:section_1) { create(:section, course: course) }
    let(:section_2) { build_stubbed(:section, course: course) }
    let(:student_1) { build_stubbed(:student) }
    let(:enrollment_1) do
      build_stubbed(:enrollment, user: student_1,
                                 section: section_1,
                                 blocked: false)
    end
    let(:form_json_1) do
      { user_id: student_1.id,
        section_id: section_1.id,
        blocked: false }.to_json
    end
    let(:student_2) { build_stubbed(:student) }
    let(:enrollment_2) do
      build_stubbed(:enrollment, user: student_2,
                                 section: section_1,
                                 blocked: true)
    end
    let(:sections) { [section_1, section_2] }
    let(:form_json_2) do
      { user_id: student_2.id,
        section_id: section_1.id,
        blocked: true }.to_json
    end
    let(:droppable_students_presenter) { double(DroppableStudentsPresenter) }

    before do
      set_up_program_and_focus(students: [student_1], sections: sections)
      allow(Enrollment).to receive(:drop_student)
      allow(controller.instance_eval { flash }).to receive(:sweep)
      allow(User).to receive(:find)
        .with([student_1.id]).and_return([student_1])
      allow(User).to receive(:find)
        .with([student_2.id]).and_return([student_2])
      allow(User).to receive(:find)
        .with([student_1.id, student_2.id])
        .and_return([student_1, student_2])
      allow(Maestro::User).to receive(:revoke_site_license_seat).and_return({})
      allow(Maestro::User).to receive(:undo_revoke_site_license_seat).and_return({})
      allow(DroppableStudentsPresenter).to receive(:new).and_return(droppable_students_presenter)
      allow(droppable_students_presenter).to receive(:droppable_students_info).and_return([])
    end

    def do_request(params={})
      default_params = { return_to: "/gradebook/#{@program.id}", program_id: @program.id }
      post :update_collection, params: default_params.merge(params)
    end

    it_should_behave_like 'an action that assigns program and focus'
    it_should_behave_like 'an action that requires a logged in instructor'

    it 'should assign a return to param' do
      do_request
      expect(assigns(:return_to)).to eq("/gradebook/#{@program.id}")
    end

    context 'when students have been selected,' do
      it 'should redirect to the return path' do
        expect(Enrollment).to receive(:drop_student).with(student_1.id, section_1.id)
        do_request(selected_student_info: [form_json_1])
      end

      it 'does not call drop if enrollment is blocked' do
        enrollment_1.state = 'dropped'
        expect(Enrollment).to receive(:drop_student)
          .with(student_1.id, section_1.id)
          .and_return(enrollment_1)
        expect(Enrollment).to_not receive(:drop_student)
          .with(student_2.id, section_1.id)
        do_request(selected_student_info: [form_json_1, form_json_2])
      end

      it 'should redirect to the return path' do
        do_request(selected_student_info: [form_json_1])
        expect(response).to redirect_to assigns(:return_to)
      end

      context 'when all students are dropped successfully' do
        let(:enrollment) { build_stubbed(:enrollment, user: student_1, section: section_1) }

        before do
          allow(enrollment).to receive(:dropped?).and_return(true)
          allow(Enrollment).to receive(:drop_student).and_return(enrollment)
        end

        it 'should set flash error be nil' do
          do_request(selected_student_info: [form_json_1])
          expect(flash[:error]).to be_nil
        end

        it 'should set a flash notice partial with information about the dropped students' do
          do_request(selected_student_info: [form_json_1])
          expect(flash[:notice_partial]).not_to be_nil
          expect(flash[:notice_partial][:partial]).to eq('/gradebook/dropped_students_flash')
        end
      end

      context 'when some students are not dropped successfully' do
        it 'should set a flash error when drop student returns nil' do
          allow(Enrollment).to receive(:drop_student).and_return(nil)
          do_request(selected_student_info: [form_json_1])
          expect(flash[:error_partial]).not_to be_nil
          expect(flash[:error_partial][:partial]).to eq('/gradebook/dropped_students_flash_error')
          expect(flash[:error_partial][:locals]).to eq(drop_student_failed_count: 1)
        end

        it 'should set a flash error when drop student returns enrollment record with errors' do
          enrollment = build_stubbed(:enrollment, user: student_1, section: section_1)
          allow(enrollment).to receive(:errors).and_return(['one error'])
          allow(Enrollment).to receive(:drop_student).and_return(enrollment)
          do_request(selected_student_info: [form_json_1])
          expect(flash[:error_partial]).not_to be_nil
          expect(flash[:error_partial][:partial]).to eq('/gradebook/dropped_students_flash_error')
          expect(flash[:error_partial][:locals]).to eq(drop_student_failed_count: 1)
        end
      end
    end

    context 'when no students are selected,' do
      before do
        allow(DroppableStudentsPresenter).to receive(:new).and_return(droppable_students_presenter)
      end

      it 'should not try to drop any students' do
        expect(Enrollment).not_to receive(:drop_students)
        do_request
      end

      it 'assigns droppable students presenter' do
        do_request
        expect(assigns[:droppable_students_presenter]).to eql droppable_students_presenter
      end

      it 'should set a flash error' do
        do_request
        expect(flash.now[:error]).to eq('You must select at least one student.')
      end

      it 'should re-render the edit_collection view' do
        do_request
        expect(response).to render_template :edit_collection
      end
    end
  end

  describe '#undrop_collection' do
    let(:cache_json) { [{ user_id: @student_1.id, section_id: @section_1.id }].to_json }
    let(:cache) { double(CacheManager, cache_get: cache_json) }

    before do
      @course = build_stubbed(:course)
      @section_1 = build_stubbed(:section, course: @course)
      @section_2 = build_stubbed(:section, course: @course)
      @student_1 = build_stubbed(:student)
      @enrollment_1 = build_stubbed(:enrollment, user: @student_1, section: @section_1)
      @sections = [@section_1, @section_2]

      set_up_program_and_focus(students: [@student_1], sections: @sections)
      allow(Enrollment).to receive(:find_by_user_id_and_sections).with(@student_1.id, @sections).and_return(@enrollment_1)
      allow(Maestro::User).to receive(:undo_revoke_site_license_seat).and_return({})
      allow(controller).to receive(:info_cache).and_return(cache)
    end

    def do_request(opts = {})
      default_params = { return_to: "/gradebook/#{@program.id}",
                         program_id: @program.id }
      post :undrop_collection, params: default_params.merge(opts)
    end

    context 'always' do
      before do
        allow(Enrollment).to receive(:undrop_student)
      end
      it_should_behave_like 'an action that assigns program and focus'
      it_should_behave_like 'an action that requires a logged in instructor'
    end

    context 'success' do
      before do
        @enrollment = build_stubbed(:enrollment, user: @student_1, section: @section_1)
        allow(Enrollment).to receive(:undrop_student).and_return(@enrollment)
      end

      it 'should set notice and error partials' do
        do_request(dropped_student_info_key: 'cache_key')
        expect(flash[:notice_partial]).not_to be_nil
        expect(flash[:notice_partial][:partial]).to eq('/gradebook/undropped_students_flash_notice')
      end
    end

    context 'failure' do
      before do
        allow(Enrollment).to receive(:undrop_student)
      end

      it 'should set flash error when undrop fails' do
        do_request
        expect(flash[:error]).to eq('Undo dropped students failed.')
      end

      it 'displays an error after undo period has expired' do
        cache = double(CacheManager, cache_get: nil)
        allow(controller).to receive(:info_cache).and_return(cache)
        do_request(dropped_student_info_key: 'expired_info_key')
        expect(flash[:error]).to eq('Undo time period has expired.')
      end
    end
  end
end

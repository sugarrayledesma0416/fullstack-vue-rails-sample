shared_examples 'when return_to param is sanitized' do
  it 'should sanitize the return_to param' do
    get :new, params: { program_id: @program.id, return_to: 'http://evil.com' }
    expect(response).to render_template 'instructor/enrollments/new'
  end
end

describe Instructor::EnrollmentsController, core: true do
  describe '#new' do
    context 'login requirement' do
      before do
        @instructor = build_stubbed(:instructor)
        allow(@instructor).to receive(:has_current_access_to?).and_return(true)
        fake_login(@instructor)
        @program = build_stubbed(:program)
        allow(Program).to receive(:find_by_id).and_return(@program)
        @section = build_stubbed(:section_with_course)
        allow(Maestro::Section).to receive(:prospective_students).and_return('student_ids' => [])
        @focus = double(Focus, sections: [@section])
        allow(Focus).to receive(:new).and_return(@focus)
      end

      def do_request
        get :new, params: { program_id: '50' }
      end

      it_should_behave_like 'an action that requires a logged in instructor'
    end

    context 'when focus has single section' do
      context 'when called without selected data' do
        before do
          @instructor = build_stubbed(:instructor)
          allow(@instructor).to receive(:has_current_access_to?).and_return(true)
          fake_login(@instructor)
          @program = build_stubbed(:program)
          @section = build_stubbed(:section_with_course)
          @selected_section = @section
          allow(@section.course.school).to receive(:students).and_return([])
          allow(Maestro::Section).to receive(:prospective_students).and_return('student_ids' => [])
          allow(Program).to receive(:find_by_id).and_return(@program)
          @focus = double(Focus, sections: [@section])
          allow(Focus).to receive(:new).and_return(@focus)
        end

        it 'should assign @program ' do
          get :new, params: { program_id: @program.id, return_to: '/something/url' }
          expect(assigns(:program)).to eq(@program)
        end

        it 'should intialize focus ' do
          expect(Focus).to receive(:new)
          get :new, params: { program_id: @program.id, return_to: '/something/url' }
        end

        it 'should assign @sections' do
          get :new, params: { program_id: @program.id, return_to: '/something/url' }
          expect(assigns(:sections)).to eq([@section])
        end

        it 'should assign @instructor' do
          get :new, params: { program_id: @program.id, return_to: '/something/url' }
          expect(assigns(:instructor)).to eq(@instructor)
        end

        include_examples 'when return_to param is sanitized'
      end

      context 'when called from with selected data' do
        let(:program)  { build_stubbed(:program) }
        let(:section)  { build_stubbed(:section_with_course) }
        let(:instructor) { build_stubbed(:instructor) }
        let(:student_1) { create(:student) }
        let(:student_2) { create(:student) }
        let(:student_3) { create(:one_roster_student) }
        let(:focus) { double(Focus, sections: [section]) }

        before do
          allow(instructor).to receive(:has_current_access_to?).and_return(true)
          allow(instructor).to receive(:setting)
          fake_login(instructor)
          allow(section.course.school).to receive(:students).and_return([])
          allow(Program).to receive(:find_by_id).and_return(program)
          allow(Focus).to receive(:new).and_return(focus)
        end

        it 'should assign selected_student and selected_section' do
          selected_students = [student_1, student_2]
          selected_student_ids = [student_1.id.to_s, student_2.id.to_s]
          allow(Section).to receive(:find).and_return(section)
          expect(Maestro::Section).to receive(:prospective_students)
            .and_return('student_ids' => selected_students.collect(&:id))
          allow(Student).to receive(:find).and_return(selected_students)
          get :new, params: { program_id: program.id, selected_section_id: section.id, selected_student_ids: selected_student_ids, return_to: '/something/url' }
          expect(assigns(:selected_student_ids)).to eq(selected_student_ids)
          expect(assigns(:selected_section)).to eq(section)
        end

        it 'should remove RA users from list of prospective students' do
          create(:one_roster_linked_user, user: student_3)
          selected_students = [student_1, student_2, student_3]
          selected_non_ra_students = [student_1, student_2]
          selected_student_ids = [student_1.id.to_s, student_2.id.to_s, student_3.id.to_s]
          allow(Section).to receive(:find).and_return(section)
          expect(Maestro::Section).to receive(:prospective_students)
                                        .and_return('student_ids' => selected_students.collect(&:id))
          allow(Student).to receive(:find).and_return(selected_students)
          get :new, params: { program_id: program.id, selected_section_id: section.id, selected_student_ids: selected_student_ids, return_to: '/something/url' }
          expect(assigns(:students).include?(student_3)).to be_falsey
        end
      end
    end
  end


  describe '#create' do
    context 'always' do
      before do
        @instructor = build_stubbed(:instructor)
        allow(@instructor).to receive(:has_current_access_to?).and_return(true)
        allow(@instructor).to receive(:setting)
        fake_login(@instructor)
        @program = build_stubbed(:program)
        allow(Program).to receive(:find_by_id).and_return(@program)

        @section = build_stubbed(:section)

        @student_1 = build_stubbed(:student)
        @student_2 = build_stubbed(:student)

        @selected_students = [@student_1, @student_2]
        @selected_student_ids = [@student_1.id.to_s, @student_2.id.to_s]
        @enrollment_map = { success: [] }
      end

      it 'searchs for the selected students and formats the notice correctly' do
        allow(Section).to receive(:find).with(@section.id).and_return(@section)
        allow(Student).to receive(:find_by_ids).and_return([@student_1, @student_2])
        allow(Enrollment).to receive(:enroll).with(@selected_students, @section).and_return(@enrollment_map)
        @enrollment_map[:success] = [1]

        notice_message = "<b>1 student</b> added to <b>#{@section.name}</b>."
        student_enroller = double(MultipleStudentEnroller,
                                  enrollment_map: @enrollment_map,
                                  flash_messages: { notice: [notice_message] })
        allow(student_enroller).to receive(:results).and_return(success: true)
        allow(student_enroller).to receive(:section_id).and_return(@section.id)
        allow(MultipleStudentEnroller).to receive(:new).and_return(MultipleStudentEnroller)
        allow(MultipleStudentEnroller).to receive(:enroll).and_return(student_enroller)

        post :create, params: { program_id: @program.id, selected_section_id: @section.id, selected_student_ids: @selected_student_ids, return_to: '/something/url' }

        expect(flash[:notice]).to eq notice_message
      end
    end
  end
end

describe RequireInstructorController, type: :controller do
  controller(described_class) do
    # The controller has a bunch of before_actions that it inherits from
    #   ApplicationController. This is to skip all of them except for the
    #   one we're testing. Then we don't have to add setup to get through
    #   the others successfully.
    before_actions = _process_action_callbacks.select do |c|
      c.kind == :before
    end.map(&:filter)

    skip_before_action *(before_actions - [:require_section_access, :archived_program_redirect])

    before_action :require_section_access
    before_action :archived_program_redirect

    def index
      render plain: 'success'
    end
  end

  describe 'require_section_access filter' do
    let(:instructor) { create(:instructor) }
    let(:non_section_instructor) { create(:instructor) }
    let(:section) { create(:section) }
    let!(:section_instructor) do
      create(:section_instructor, section_id: section.id,
                                  user_id: instructor.id)
    end
    let(:program) { create(:program) }

    before do
      allow(@controller).to receive(:current_program).and_return(program)
    end

    context 'when the current user is an instructor for the section' do
      it 'succeeds' do
        allow(@controller).to receive(:current_user).and_return(instructor)
        get :index, params: { section_id: section.id }

        expect(response).to be_successful
      end
    end

    context 'when the current user is not an instructor for the section' do
      it 'redirects to the dashboard and notifies the user' do
        allow(@controller).to receive(:current_user).and_return(non_section_instructor)
        get :index, params: { section_id: section.id }

        expect(flash[:error]).to eq 'This page requires instructor access to the current section.'
        expect(response).to redirect_to instructor_dashboard_path(program)
      end
    end
  end

  describe 'archived_program_redirect filter' do
    let(:instructor) { create(:instructor) }
    let(:non_section_instructor) { create(:instructor) }
    let(:section) { create(:section) }
    let!(:section_instructor) do
      create(:section_instructor, section_id: section.id,
                                  user_id: instructor.id)
    end

    before do
      allow(@controller).to receive(:current_user).and_return(instructor)
    end

    context 'when the current program is not archived' do
      it 'succeeds' do
        program = create(:program)
        allow(@controller).to receive(:current_program).and_return(program)
        get :index, params: { section_id: section.id }

        expect(response).to be_successful
      end
    end

    context 'when the current program is archived' do
      it 'redirects to the archived program landing page' do
        program = create(:program, is_archived: true)
        allow(@controller).to receive(:current_program).and_return(program)
        get :index, params: { section_id: section.id }

        expect(response).to redirect_to "#{UA_URL}/archived/#{program.id}"
      end
    end
  end

  describe '#check_access' do
    let(:program) { create(:program) }
    let(:section) { create(:section) }
    let(:students) { create_list(:student, 2) }
    let(:gb_students) { [gb_student(students[0], true), gb_student(students[1], true)] }

    def gb_student(student, sufficient_access)
      instance_double(GradebookStudent, student:, sufficient_access?: sufficient_access)
    end

    before do
      allow(GradebookStudent).to receive(:decorate).and_return(gb_students)
    end

    context 'when all students have sufficient access' do
      it 'returns false' do
        expect(controller.check_access(gb_students)).to be(false)
      end

      it('sets @has_access_problem to false', :aggregate_failures) do
        expect(controller.instance_variable_get(:@has_access_problem)).to be_nil

        controller.check_access(gb_students)
        expect(controller.instance_variable_get(:@has_access_problem)).to be(false)
      end
    end

    context 'when a student does not have sufficient access' do
      let(:gb_students) { [gb_student(students[0], true), gb_student(students[1], false)] }

      it 'returns true' do
        expect(controller.check_access(gb_students)).to be(true)
      end

      it('sets @has_access_problem to true', :aggregate_failures) do
        expect(controller.instance_variable_get(:@has_access_problem)).to be_nil

        controller.check_access(gb_students)
        expect(controller.instance_variable_get(:@has_access_problem)).to be(true)
      end
    end

    context 'when the decorated_students param is specified' do
      let(:decorated_students) do
        [
          instance_double(GradebookStudent, sufficient_access?: true),
          instance_double(GradebookStudent, sufficient_access?: false)
        ]
      end

      before do
        allow(GradebookStudent).to receive(:has_access_problem?).and_return(false)
      end

      it 'sets @has_access_problem using the provided decorated students' do
        controller.check_access(decorated_students)
        expect(controller.instance_variable_get(:@has_access_problem)).to be(true)
      end

      it 'does not call GradebookStudent.has_access_problem?' do
        controller.check_access(decorated_students)
        expect(GradebookStudent).not_to have_received(:has_access_problem?)
      end

      it 'does not get decorated students again' do
        controller.check_access(gb_students)
        expect(GradebookStudent).not_to have_received(:decorate)
      end
    end

    context 'when the decorated_students param is not specified' do
      let(:current_focus) { instance_double(Focus, sections: [section]) }

      before do
        allow(controller).to receive(:current_focus).and_return(current_focus)
        allow(controller).to receive(:current_program).and_return(program)
        allow(GradebookStudent).to receive(:has_access_problem?).and_return(false)
      end

      it 'sets @has_access_problem using GradebookStudent' do
        controller.check_access
        expect(controller.instance_variable_get(:@has_access_problem)).to be(false)
      end

      it 'calls GradebookStudent.has_access_problem? with correct parameters' do
        controller.instance_variable_set(:@students, students)
        controller.check_access

        expect(GradebookStudent).to have_received(:has_access_problem?).with(
          students, program, [section]
        )
      end
    end
  end

  describe 'filter_gb_sections' do
    let(:owner) { create(:instructor) }
    let(:co_ins) { create(:instructor) }
    let(:section_1) { create(:section) }
    let(:section_2) { create(:section) }
    let(:gb_section_1) { create(:gb_section, id: section_1.id) }
    let(:gb_section_2) { create(:gb_section, id: section_2.id) }
    let(:gb_sections) { [gb_section_1, gb_section_2] }

    before do
      create(
        :section_instructor,
        section: section_1,
        user_id: owner.id,
        role: 'Instructor'
      )
      create(
        :section_instructor,
        section: section_2,
        user_id: owner.id,
        role: 'Instructor'
      )
      create(
        :section_instructor,
        section: section_2,
        user_id: co_ins.id,
        role: 'Co-Instructor'
      )
    end

    it 'returns only sections for the co-instructor' do
      allow(@controller).to receive(:current_user).and_return(co_ins)
      expect(@controller.filter_gb_sections(gb_sections)).to eq([gb_section_2])
    end

    it 'returns all sections for the owner' do
      allow(@controller).to receive(:current_user).and_return(owner)
      expect(@controller.filter_gb_sections(gb_sections)).to eq(
        [gb_section_1, gb_section_2]
      )
    end
  end
end

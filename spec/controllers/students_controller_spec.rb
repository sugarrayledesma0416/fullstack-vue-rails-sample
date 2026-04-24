describe StudentsController do
  let(:student) { build_stubbed(:student) }

  before { allow(GradebookStudent).to receive(:decorate).and_return(student) }

  describe '#enrollment_info' do
    before do
      @student = create(:student)
      @instructor = create(:instructor)
      @school = create(:school)

      @school.students << @student
      @school.instructors << @instructor
    end

    context 'when the logged-in user is an instructor' do
      before do
        fake_login(@instructor)
      end

      context 'when the student is at the same school as the instructor' do
        before do
          get :enrollment_info, params: { student_id: @student.id, school_id: @school.id }
        end

        it 'returns a 200' do
          expect(response.code).to eq('200')
        end

        it 'assigns the correct instance variables' do
          expect(assigns(:school)).to eql @school
          expect(assigns(:student)).to eql @student
          expect(assigns(:thumb_url)).to_not be_nil
        end
      end

      context 'when the student is at a different school than the instructor' do
        it 'returns a 403' do
          student = create(:student)
          get :enrollment_info, params: { student_id: student.id, school_id: @school.id }
          expect(response.code).to eq('403')
        end
      end
    end

    context 'when the logged-in user is a student' do
      before do
        fake_login(@student)
      end

      it 'returns a 403' do
        get :enrollment_info, params: { student_id: @student.id, school_id: @school.id }
        expect(response.code).to eq('403')
      end
    end
  end

  describe "#student_info'" do
    let(:section) { build_stubbed(:section) }
    let(:program) { build_stubbed(:program) }
    let(:gb_student) { instance_double(GradebookStudent) }

    before do
      @user = build_stubbed(:instructor)
      fake_login(@user)

      allow(User).to receive(:find).and_return(student)
      allow(Program).to receive(:find).and_return(program)
      allow(Section).to receive(:find).and_return(section)
      allow(GradebookStudent).to receive(:decorate).and_return(gb_student)

      @params = { id: student.id.to_s, program_id: program.id, section_id: section.id.to_s }
    end

    def do_request
      get :student_info, params: @params
    end

    it 'is successful' do
      do_request
      expect(response).to be_successful
    end

    it 'renders the student_info template' do
      do_request
      expect(response).to render_template(:student_info)
    end

    it 'assigns the presenter' do
      do_request
      expect(assigns(:presenter)).not_to be_nil
    end

    it 'sends the expected parameters to GradebookStudent.decorate' do
      do_request
      expect(GradebookStudent).to have_received(:decorate).with(student, program, [section])
    end
  end

  describe 'GET update_student_avatar' do
    before do
      @user = build_stubbed(:instructor)
      fake_login(@user)
      allow(User).to receive(:find).and_return(student)
      @params = { id: student.id.to_s }
    end

    def do_request
      get :update_student_avatar, params: @params, xhr: true
    end

    it 'is successful' do
      do_request
      expect(response).to be_successful
    end

    it 'renders a json containing thumbnail path' do
      json_rendering_params = { thumbnail_path: student.avatar_thumb_url, avatar_path: student.avatar_image_url }
      do_request
      expect(response.status).to eql(200)
      expect(response.content_type).to eql('application/json; charset=utf-8')
      expect(response.body).to eql(JSON.generate(json_rendering_params))
    end
  end
end

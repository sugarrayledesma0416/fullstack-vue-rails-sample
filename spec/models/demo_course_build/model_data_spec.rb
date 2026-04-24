module DemoCourseBuild
  describe ModelData do
    let(:program) { create(:program) }
    let(:model_instructor) { create(:instructor, username: 'model_demo_instructor') }
    let(:model_student_1) { create(:student, username: 'model_demo_student_1') }
    let(:model_student_2) { create(:student, username: 'model_demo_student_2') }
    let(:model_course) { create(:course, name: 'Trial Course',
                                         program: program,
                                         owner: model_instructor) }
    let(:model_section) { create(:section, name: 'Trial Section',
                                           course: model_course,
                                           instructor_id: model_instructor.id) }
    let(:model_data) { ModelData.new(program: program) }

    before do
      model_section.students.concat([model_student_1, model_student_2])
    end

    describe '#model_instructor' do
      it 'returns the model instructor record' do
        expect(model_data.model_instructor.username).to eq('model_demo_instructor')
      end
    end

    describe '#model_course' do
      it 'returns the model course for the program' do
        course = model_data.model_course
        expect(course.name).to eq('Trial Course')
        expect(course.program_id).to eq program.id
        expect(course.owner_id).to eq model_instructor.id
      end

      it 'returns nil when there is no model course for the program' do
        expect(ModelData.new(program: create(:program)).model_course).to be_nil
      end
    end

    describe '#model_section' do
      it 'returns the section associated with the model course' do
        section = model_data.model_section
        expect(section.name).to eq 'Trial Section'
        expect(section.instructor_id).to eq model_instructor.id
        expect(section.course.id).to eq model_course.id
      end
    end

    describe '#model_students' do
      it 'returns the students enrolled in the model section' do
        students = model_data.model_students
        expect(students.map(&:id)).to match [model_student_1.id, model_student_2.id]
      end
    end

    describe '#model_data_exists?' do
      it 'returns true when all model data is found' do
        expect(model_data.model_data_exists?).to be_truthy
      end

      it 'returns false when something is missing and adds an error' do
        allow(model_data).to receive(:model_students).and_return([])
        expect(model_data.model_data_exists?).to be_falsey
        expect(model_data.errors).to_not be_empty
      end
    end
  end
end

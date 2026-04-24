describe DemoCourseBuild::Creator do
  let(:owner) { create(:instructor) }
  let(:program) { create(:program) }
  let(:student_1) { create(:fake_student) }
  let(:student_2) { create(:fake_student) }
  let(:school) { create(:school) }
  let(:valid_params) do
    {
      owner_id: owner.id,
      program_id: program.id,
      student_ids: [student_1.id, student_2.id]
    }
  end

  before do
    owner.schools << school
  end

  describe 'validations' do
    it 'requires a non blank owner_id param' do
      creator = described_class.new(valid_params.merge(owner_id: nil))
      creator.create_course
      expect(creator.status).to eq(:unprocessable_entity)
      expect(creator.message[:errors]).to eq(
        base: ['owner_id param was missing or blank']
      )
    end

    it 'requires that an instructor exists matching the specified owner_id' do
      owner.destroy
      creator = described_class.new(valid_params)
      creator.create_course
      expect(creator.status).to eq(:unprocessable_entity)
      expect(creator.message[:errors]).to eq(
        base: ["no Instructor exists matching owner_id: #{owner.id}"]
      )
    end

    it 'requires that the specified instructor has a school' do
      owner.schools.each(&:destroy)
      creator = described_class.new(valid_params)
      creator.create_course
      expect(creator.status).to eq(:unprocessable_entity)
      expect(creator.message[:errors]).to eq(
        base: ["Instructor with id: #{owner.id} has no school"]
      )
    end

    it 'requires a non-blank program_id param' do
      creator = described_class.new(valid_params.merge(program_id: nil))
      creator.create_course
      expect(creator.status).to eq(:unprocessable_entity)
      expect(creator.message[:errors]).to eq(
        base: ['program_id param was missing or blank']
      )
    end

    it 'requires that a program exists matching the specified program_id' do
      program.destroy
      creator = described_class.new(valid_params)
      creator.create_course
      expect(creator.status).to eq(:unprocessable_entity)
      expect(creator.message[:errors]).to eq(
        base: ["no Program exists matching program_id: #{program.id}"]
      )
    end

    it 'requires at least one non-blank student_id' do
      creator = described_class.new(valid_params.merge(student_ids: nil))
      creator.create_course
      expect(creator.status).to eq(:unprocessable_entity)
      expect(creator.message[:errors]).to eq(
        base: ['student_ids param was missing or blank']
      )
    end

    it 'requires that students exist matching the specified student ids' do
      student_1.destroy
      creator = described_class.new(valid_params)
      creator.create_course
      expect(creator.status).to eq(:unprocessable_entity)
      expect(creator.message[:errors]).to eq(
        base: ["no Student exists with specified id: #{student_1.id}"]
      )
    end
  end

  context 'with valid params' do
    let(:creator) { described_class.new(valid_params) }
    let(:demo_course) { build_stubbed(:course, owner: owner) }
    let(:demo_section) do
      build_stubbed(:section, course: demo_course, instructor_id: owner.id)
    end
    let(:no_errors) do
      instance_double(ActiveModel::Errors, full_messages: [], empty?: true)
    end
    let(:demo_course_creator) do
      instance_double(DemoCourseBuild::Course, create_demo_course: demo_course)
    end
    let(:demo_section_creator) do
      instance_double(DemoCourseBuild::Section, create_demo_section: demo_section)
    end
    let(:copier) do
      instance_double(
        DemoCourseBuild::CourseDataCopier,
        populate_demo_course_data: true,
        errors: no_errors
      )
    end
    let(:model_course) { build_stubbed(:course) }
    let!(:model_section) { build_stubbed(:section) }
    let(:model_students) { [build_stubbed(:student), build_stubbed(:student)] }
    let(:model_data) do
      instance_double(
        DemoCourseBuild::ModelData,
        model_instructor: build_stubbed(:instructor),
        model_course: model_course,
        model_section: model_section,
        model_students: model_students,
        model_data_exists?: true
      )
    end

    before do
      allow(DemoCourseBuild::Course).to receive(:new).and_return(demo_course_creator)
      allow(DemoCourseBuild::Section).to receive(:new).and_return(demo_section_creator)
      allow(DemoCourseBuild::ModelData).to receive(:new).and_return(model_data)
      allow(DemoCourseBuild::CourseDataCopier).to receive(:new).and_return(copier)
      allow(Enrollment).to receive(:enroll_demo_students)
    end

    it 'creates a demo course for the specified instructor and program' do
      expected_params = { program: program, owner: owner }

      creator.create_course

      expect(DemoCourseBuild::Course).to have_received(:new)
        .with(hash_including(expected_params))
      expect(demo_course_creator).to have_received(:create_demo_course)
    end

    it 'creates a demo section for the course' do
      expected_params = { owner: owner, course: demo_course }

      creator.create_course

      expect(DemoCourseBuild::Section).to have_received(:new)
        .with(hash_including(expected_params))
      expect(demo_section_creator).to have_received(:create_demo_section)
    end

    it 'creates a data copier to build out the section data' do
      expected_params = {
        demo_course: demo_course,
        demo_section: demo_section,
        model_course: model_course,
        students: [student_1, student_2]
      }

      creator.create_course

      expect(DemoCourseBuild::CourseDataCopier).to have_received(:new)
        .with(hash_including(expected_params))
    end

    it 'sets up the new demo course and section' do
      expect(copier).to receive(:populate_demo_course_data)
      creator.create_course
    end

    context 'when successful' do
      before do
        creator.create_course
      end

      it 'sets status to ok' do
        expect(creator.status).to eql :ok
      end

      it 'sets message to success' do
        expect(creator.message).to eql 'success'
      end

      it 'returns true' do
        expect(creator.create_course).to be_truthy
      end
    end

    context 'when course creation fails' do
      before do
        demo_course.errors.add(:base, 'something went wrong')
        allow(demo_course).to receive(:valid?).and_return(false)
      end

      it 'notifies VHLMonitor' do
        expect(VHLMonitor).to receive(:notify)
        creator.create_course
      end

      it 'sets status to unprocessable_entity' do
        creator.create_course
        expect(creator.status).to eql :unprocessable_entity
      end

      it 'sets message to errors from demo course' do
        creator.create_course
        expect(creator.message[:errors]).to eq(
          base: ['something went wrong']
        )
      end

      it 'returns false' do
        expect(creator.create_course).to be_falsey
      end
    end

    context 'when the course creation generates an exception,' do
      it 'is logged by VHLMonitor' do
        expected_error = StandardError.new('error creating the course')

        expect(demo_course_creator)
          .to receive(:create_demo_course)
          .and_raise(expected_error)
        expect(VHLMonitor).to receive(:notify).with(expected_error)
        creator.create_course
      end
    end

    context 'when the section creation generates an exception,' do
      expected_error = StandardError.new('error creating the section')
      it 'is logged by VHLMonitor' do
        expect(demo_section_creator)
          .to receive(:create_demo_section)
          .and_raise(expected_error)
        expect(VHLMonitor).to receive(:notify).with(expected_error)
        creator.create_course
      end
    end

    context 'when data population generates an exception,' do
      expected_error = StandardError.new('error copying data')
      it 'is logged by VHLMonitor' do
        expect(copier)
          .to receive(:populate_demo_course_data)
          .and_raise(expected_error)
        expect(VHLMonitor).to receive(:notify).with(expected_error)
        creator.create_course
      end
    end
  end
end

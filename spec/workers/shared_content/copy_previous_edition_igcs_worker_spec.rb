RSpec.describe SharedContent::CopyPreviousEditionIgcsWorker do
  describe '#perform' do
    let(:previous_program_id) { 1 }
    let(:program_id) { 2 }
    let(:instructor_id) { 3 }
    let(:activities_to_copy_ids) { [4, 5, 6] }
    let(:previous_program) { instance_double(Program, id: previous_program_id) }
    let(:program) { instance_double(Program, id: program_id) }
    let(:instructor) { instance_double(Instructor, id: instructor_id) }
    let(:activities_to_copy) do
      [instance_double(InstructorCreatedActivity, id: 4),
       instance_double(InstructorCreatedActivity, id: 5),
       instance_double(InstructorCreatedActivity, id: 6)]
    end
    let(:copier) { instance_double(ProgramPreviousEditionIgcCopier) }

    before do
      allow(Program).to receive(:find).with(previous_program_id).and_return(previous_program)
      allow(Program).to receive(:find).with(program_id).and_return(program)
      allow(Instructor).to receive(:find).with(instructor_id).and_return(instructor)
      allow(InstructorCreatedActivity).to receive(:where).with(id: activities_to_copy_ids).and_return(activities_to_copy)

      allow(ProgramPreviousEditionIgcCopier).to receive(:new).with(
        previous_program, program, instructor, activities_to_copy
      ).and_return(copier)

      allow(copier).to receive(:copy_previous_edition_igcs)
    end

    it 'enqueues the job' do
      expect do
        described_class.perform_async(previous_program_id, program_id,
                                      instructor_id, activities_to_copy_ids)
      end.to change(described_class.jobs, :size).by(1)
    end

    it 'finds the required records and initializes the copier' do
      described_class.new.perform(previous_program_id, program_id,
                                  instructor_id, activities_to_copy_ids)

      expect(Program).to have_received(:find).with(previous_program_id)
      expect(Program).to have_received(:find).with(program_id)
      expect(Instructor).to have_received(:find).with(instructor_id)
      expect(InstructorCreatedActivity).to have_received(:where).with(id: activities_to_copy_ids)
      expect(ProgramPreviousEditionIgcCopier).to have_received(:new).with(
        previous_program, program, instructor, activities_to_copy
      )
    end

    it 'calls the copier to perform the copy operation' do
      described_class.new.perform(previous_program_id, program_id,
                                  instructor_id, activities_to_copy_ids)
      expect(copier).to have_received(:copy_previous_edition_igcs)
    end

    context 'when an exception occurs' do
      before do
        allow(copier).to receive(:copy_previous_edition_igcs).and_raise(StandardError.new('something went wrong'))
      end

      it 'rescues from StandardError' do
        expect do
          described_class.new.perform(previous_program_id, program_id,
                                      instructor_id, activities_to_copy_ids)
        end.not_to raise_error
      end
    end
  end
end

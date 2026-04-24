RSpec.describe ProgramPreviousEditionIgcCopier do
  describe '#copy_previous_edition_igcs' do
    subject(:copier) do
      described_class.new(previous_program, program, instructor, activities_to_copy)
    end

    let(:previous_program) { create(:program) }
    let(:program) { create(:program) }
    let(:instructor) { create(:instructor) }
    let(:activities_to_copy) { create_list(:instructor_created_activity, 3) }
    let(:igc_copy_job) { instance_double(IgcCopyJob, save!: true, run: true) }

    before do
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_concept)
      allow(Maestro::LicenseGroup).to receive(:all).and_return([double(id: 1,
                                                                       name: 'Test License Group')])
      allow(IgcCopyJob).to receive(:where).and_return(IgcCopyJob)
      allow(IgcCopyJob).to receive(:first_or_initialize).and_return(igc_copy_job)
      allow(igc_copy_job).to receive(:to_be_copied_ids=)
      allow(igc_copy_job).to receive(:copied_ids).and_return([])
      allow(igc_copy_job).to receive(:copied_ids=)
    end

    it 'initializes or finds an IgcCopyJob with correct parameters' do
      expect(IgcCopyJob).to receive(:where).with(hash_including(
                                                   src_program_id: previous_program.id,
                                                   dest_program_id: program.id,
                                                   instructor_id: instructor.id
                                                 ))
      expect(igc_copy_job).to receive(:to_be_copied_ids=).with(activities_to_copy.map(&:id))
      copier.copy_previous_edition_igcs
    end

    it 'saves and runs the IgcCopyJob' do
      expect(igc_copy_job).to receive(:save!)
      expect(igc_copy_job).to receive(:run)
      copier.copy_previous_edition_igcs
    end

    context 'when an exception occurs during the job saving' do
      before do
        allow(igc_copy_job).to receive(:save!).and_raise(StandardError.new('Error saving job'))
      end

      it 'logs an error and does not raise the exception' do
        expect(Rails.logger).to receive(:error).with('Error copying previous edition IGCS: Error saving job')
        expect { copier.copy_previous_edition_igcs }.not_to raise_error
      end
    end

    context 'when an exception occurs during the job run' do
      before do
        allow(igc_copy_job).to receive(:run).and_raise(StandardError.new('Error running job'))
      end

      it 'logs an error and does not raise the exception' do
        expect(Rails.logger).to receive(:error).with('Error copying previous edition IGCS: Error running job')
        expect { copier.copy_previous_edition_igcs }.not_to raise_error
      end
    end
  end
end

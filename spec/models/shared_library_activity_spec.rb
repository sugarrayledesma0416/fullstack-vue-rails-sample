describe SharedLibraryActivity do
  let(:instructor) { create(:instructor) }
  let(:school) { create(:school) }
  let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
  let(:unit) { create(:unit, program: program) }
  let(:program) { create(:program) }
  let(:strand) { create(:toc_entry) }
  let(:igc_activity) do
    create(:instructor_created_activity, lesson: lesson, toc_entry_id: strand.location)
  end
  let(:activity_copy) do
    create(:instructor_created_activity, lesson: lesson, toc_entry_id: strand.location)
  end
  let(:activity) { create(:activity) }
  let(:shared_library_activity) { create(:shared_library_activity,
                                         source_activity: igc_activity,
                                         activity: activity_copy,
                                         school: school) }

  let(:approved_shared_library_activity) { create(:shared_library_activity,
                                         source_activity: igc_activity,
                                         activity: activity_copy,
                                         is_shared: true,
                                         school: school) }

  before do
    create(:concept, lesson: lesson, program: program, id: strand.location)
    allow(Maestro::LicenseGroup).to receive(:all).and_return(
      [instance_double(Maestro::LicenseGroup, id: 1, name: '01-Supersite')]
    )
    stub_request(:any, %r{https\://s3\.amazonaws\.com/vhlcentral\.activities/.*\.xml})
      .to_return(status: 200, body: '', headers: {})
  end

  describe 'validations' do
    it 'requires a school' do
      shared_library_activity = described_class.new(source_activity: igc_activity,
                                                    school: nil)
      expect(shared_library_activity).not_to be_valid
    end

    it 'requires an activity_id' do
      shared_library_activity = described_class.new(activity: nil,
                                                    school: school)
      expect(shared_library_activity).not_to be_valid
    end

    it 'can be associated with an igc activity' do
      with_igc_activity = described_class.new(source_activity: igc_activity,
                                              school: school)
      expect(with_igc_activity).to be_valid
    end

    it 'cannot be associated with a regular activity' do
      expect do
        described_class.new(activity: activity,
                            school: school)
      end.to raise_error ActiveRecord::AssociationTypeMismatch
    end

    it 'can be associated with a school' do
      shared_library_activity
      expect(shared_library_activity.school).to eq school
    end
  end

  describe '#approve_shared_activity' do
    describe 'when Institution Admin approved the request to share one activity' do
      it 'updates the shared_library_activity record' do
        shared_library_activity.approve_shared_activity
        expect(shared_library_activity.is_shared).to be true
      end
    end
  end

  describe '#approve_allow_copy' do
    describe 'when the institution admin allows copy of the approved shared activity' do
      it 'updates the shared_library_activity record' do
        shared_library_activity.approve_allow_copy
        expect(shared_library_activity.allow_copy).to be true
      end
    end
  end

  describe '.cancel_shared_activity_request' do
    describe 'when Institution Admin denied the request to share one activity' do
      it 'deletes the shared_library_activity record for source_activity_id' do
        shared_library_activity
        approved_shared_library_activity
        expect do
          described_class.cancel_shared_activity_request(igc_activity)
        end.to change(described_class, :count).by(-1)
      end

      it 'does not delete already approved items for source_activity_id' do
        approved_shared_library_activity
        expect do
          described_class.cancel_shared_activity_request(igc_activity)
        end.to change(described_class, :count).by(0)
      end
    end
  end

  describe '.remove_shared_activity' do
    describe 'when Institution Admin deletes the shared activity from the library' do
      it 'deletes the shared library activity record for activity_id' do
        shared_library_activity
        expect do
          described_class.remove_shared_activity(activity_copy)
        end.to change(described_class, :count).by(-1)
      end
    end
  end

  describe '.assign_activity_copy_id_and_approver' do
    it 'updates the shared library activity activity_id and institution_admin_approver_id' do
      shared_library_activity
      described_class.assign_activity_copy_id_and_approver(igc_activity.id,
                                                           activity.id,
                                                           school.id,
                                                           instructor.id)
      shared_library_activity.reload
      expect(shared_library_activity.activity_id).to eq activity.id
      expect(shared_library_activity.institution_admin_approver_id).to eq instructor.id
    end
  end

  describe '.shared_activity_record' do
    it 'get a record of shared library activity to get the school and source activity attributes' do
      shared_library_activity
      expect(described_class.shared_activity_record(activity_copy)).to eq shared_library_activity
    end
  end
end

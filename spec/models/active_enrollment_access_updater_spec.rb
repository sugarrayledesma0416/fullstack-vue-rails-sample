describe ActiveEnrollmentAccessUpdater do
  describe '#update' do
    let!(:student) { create(:student) }
    let!(:section) { create(:section) }
    let(:access_updater) { described_class.new(student, section) }

    it 'does not generate an error if the enrollment does not exist' do
      expect { access_updater.update }.not_to raise_error
    end

    it 'does not update the enrollment if it is in a non active state' do
      enrollment = create(:transferred_enrollment, section:, user: student, sufficient_access: false)
      access_updater.update

      expect(enrollment.reload.sufficient_access).to be false
    end

    describe 'with an active enrollment' do
      let!(:enrollment) do
        create(:active_enrollment, section:, user: student, sufficient_access: false)
      end

      before do
        allow(Maestro::Enrollment).to receive(:check_licenses).with([enrollment.guid]).and_return(
          { 'enrollment_ids' => [enrollment.id] }
        )
      end

      it 'updates the enrollment if the student does not have sufficient access' \
         'but API says it should' do
        access_updater.update

        expect(enrollment.reload.sufficient_access).to be true
      end

      it 'does not call API if the student has sufficient access' do
        enrollment.update!(sufficient_access: true)
        access_updater.update

        expect(Maestro::Enrollment).not_to have_received(:check_licenses)
      end

      it 'does not update the enrollment if the student does not have sufficient access' \
         'and API confirms it' do
        allow(Maestro::Enrollment).to receive(:check_licenses).with([enrollment.guid]).and_return(
          { 'enrollment_ids' => [] }
        )
        access_updater.update

        expect(enrollment.reload.sufficient_access).to be false
      end

      it 'does not update the enrollment if it is for another section' do
        access_updater = described_class.new(student, create(:section))
        access_updater.update

        expect(enrollment.reload.sufficient_access).to be false
      end
    end
  end
end

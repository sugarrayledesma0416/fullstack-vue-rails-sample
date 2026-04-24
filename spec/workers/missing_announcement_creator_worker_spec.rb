describe MissingAnnouncementCreatorWorker do

  let(:student) { create(:student) }
  let(:section) { create(:section) }

  describe '#perform' do
    before do
      allow(Announcement).to receive(:create_missing_notifications_for_student_in_section)
    end

    context 'when the section can be found' do
      it 'tells Announcement to create missing notifications for the student ' \
         'in the section they are joining' do
        described_class.new.perform(student.id, section.id)
        expect(Announcement).to have_received(
          :create_missing_notifications_for_student_in_section
        ).with(student, section)
      end
    end

    context 'when the section cannot be found' do
      it 'does not do the call to create missing notifications if the section is enterprise' do
        section = create(:enterprise_section)
        described_class.new.perform(student.id, section.id)
        expect(Announcement).not_to have_received(
          :create_missing_notifications_for_student_in_section
        )
      end

      it 'does not do the call to create missing notifications if the section is archived' do
        section = create(:archived_section_in_archived_course)
        described_class.new.perform(student.id, section.id)
        expect(Announcement).not_to have_received(
          :create_missing_notifications_for_student_in_section
        )
      end
    end
  end
end

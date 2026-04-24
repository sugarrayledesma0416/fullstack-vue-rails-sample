describe SectionArchiver, core: true do

  before do
    Dangerfield::Gatekeeper.instance.disabled = true
  end

  let(:section) { create(:section_with_course) }

  describe '#archive' do
    context 'when a section is a normal vhlcentral section' do
      it 'archives the section but not the course' do
        course = section.course
        described_class.new.archive(section)
        expect(section.reload).to be_archived
        expect(section.course).not_to be_archived
      end

      it 'returns a success message for display' do
        sa = described_class.new
        expect(sa.archive(section)).to be_truthy
        expect(sa.success_message).to eq "Section <b>#{section.name}</b> was deleted successfully."
      end

      it 'reports an error when section archiving fails' do
        sa = described_class.new
        sa.errors = ['something went wrong.']
        expect(sa.archive(section)).to be_falsey
        expect(sa.error_message).to eq 'something went wrong.'
      end
    end

    context 'when a section is an Lti-rostering section' do
      it 'archives the section and the course' do
        lti_rostering_instructor = create(:lti_rostering_instructor)
        create(:lti_rostering_user_link, user: lti_rostering_instructor)
        lti_rostering_section = create(:section_with_course, instructor: lti_rostering_instructor)
        create(:lti_context_link, section: lti_rostering_section)
        course = lti_rostering_section.course
        described_class.new.archive(lti_rostering_section)
        expect(lti_rostering_section.reload).to be_archived
        expect(course.reload).to be_archived
      end
    end
  end
end

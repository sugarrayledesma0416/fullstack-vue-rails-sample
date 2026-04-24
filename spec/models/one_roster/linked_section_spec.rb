describe OneRoster::LinkedSection do
  let(:section) { build(:section) }
  let(:class_external_id) { SecureRandom.uuid }
  let(:course_external_id) { SecureRandom.uuid }

  describe '.build_identifier' do
    it 'creates a string identifier with the given params' do
      result = described_class.build_identifier(course_external_id, class_external_id)
      expect(result).to eq "#{course_external_id}::#{class_external_id}"
    end
  end

  describe '.validations' do
    it 'requires a section' do
      linked_section = described_class.new(course_external_id: course_external_id,
                                           class_external_id: class_external_id)
      expect(linked_section).not_to be_valid
      expect(linked_section.errors.full_messages).to include 'Section must exist'
    end

    it 'requires a course_external_id' do
      linked_section = described_class.new(section: section,
                                           class_external_id: class_external_id)
      expect(linked_section).not_to be_valid
      expect(linked_section.errors.full_messages).to include 'Course external is required'
    end

    it 'requires a class_external_id' do
      linked_section = described_class.new(section: section,
                                           course_external_id: course_external_id)
      expect(linked_section).not_to be_valid
      expect(linked_section.errors.full_messages).to include 'Class external is required'
    end
  end

  describe '#academic_session' do
    it 'saves as a JSON object' do
      academic_sessions = [
        {
          'start_date' => 1.day.ago.strftime('%Y-%m-%d'),
          'end_date' => 10.days.from_now.strftime('%Y-%m-%d'),
          'school_year' => Time.now.strftime('%Y')
        }
      ]
      linked_section = described_class.new(section: section,
                                           course_external_id: course_external_id,
                                           class_external_id: class_external_id,
                                           academic_session: academic_sessions)
      linked_section.save!
      linked_section.reload
      expect(linked_section.read_attribute_before_type_cast('academic_session'))
        .to eq academic_sessions.to_json
    end
  end

  describe '#identifier' do
    it 'returns the linked section identifier' do
      linked_section = described_class.new(section: section,
                                           course_external_id: course_external_id,
                                           class_external_id: class_external_id)
      expected_hash = {
        "#{course_external_id}::#{class_external_id}" => section
      }
      expect(linked_section.identifier).to eq expected_hash
    end
  end

  it 'returns only unarchived records' do
    unarchived_linked_section = create(:one_roster_linked_section)
    create(:one_roster_linked_section, is_archived: true)
    expect(OneRoster::LinkedSection.all).to eq [unarchived_linked_section]
  end
end

describe SectionInstructor do
  before do
    Dangerfield::Gatekeeper.instance.disabled = true
  end

  describe 'scopes' do
    describe '.responsible' do
      before do
        @assistant = create(:section_instructor, role: 'Assistant')
        @instructor = create(:section_instructor, role: 'Instructor')
        @co_instructor = create(:section_instructor, role: 'Co-instructor')
        @another_role = create(:section_instructor, role: 'another_role')
      end

      it 'returns section instructors expect ones for assistant instructors' do
        expect(SectionInstructor.responsible).to include @instructor
        expect(SectionInstructor.responsible).to include @co_instructor
        expect(SectionInstructor.responsible).to include @assistant
        expect(SectionInstructor.responsible).to_not include @another_role
      end
    end
  end

  describe 'validations' do
    it 'requires an instructor_id' do
      section_instructor = SectionInstructor.new
      expect(section_instructor).to_not be_valid

      expected_error = I18n.t('activerecord.errors.messages')[:blank]
      expect(section_instructor.errors[:user_id]).to include expected_error
    end

    context 'uniqueness constraints' do
      it 'prevents the same section_id and user_id combination' do
        instructor = create(:instructor)
        course = build_stubbed(:course)
        section = create(:section, course: course)
        create(:section_instructor, instructor: instructor, section: section)

        si = build(:section_instructor, instructor: instructor, section: section)
        expect(si).not_to be_valid
        expect(si.errors[:user_id]).to include I18n.t('activerecord.errors.messages')[:taken]
      end
    end

    context 'validate assign_rostering_attrs' do
      it 'sets guid, request_id' do
        Dangerfield::Gatekeeper.instance.disabled = false
        instructor = create(:instructor)
        course = build_stubbed(:course)
        section = create(:section, course: course)
        test_section_instructor = create(
          :section_instructor,
          instructor: instructor,
          section: section
        )
        expect(test_section_instructor.guid).not_to be_nil
        expect(test_section_instructor.request_id).not_to be_nil
        Dangerfield::Gatekeeper.instance.disabled = true
      end
    end
  end

  it_behaves_like 'a model with enterprise section validation' do
    subject(:model) { build_stubbed(:section_instructor, instructor:, section:) }

    let(:instructor) { build_stubbed(:instructor) }
  end

  describe '#instructor' do
    let(:course) { build_stubbed(:course) }
    let(:section) { create(:section, course: course) }

    it 'returns the active instructor of a section' do
      instructor = create(:instructor)
      si = build(:section_instructor, instructor: instructor, section: section)

      expect(si.instructor).to eq(instructor)
    end

    it 'returns the archived instructor of a section' do
      instructor = create(:instructor, archived: 1)
      si = build(:section_instructor, instructor: instructor, section: section)

      expect(si.instructor).to eq(instructor)
    end
  end
end

describe CourseInstructorPolicy do
  def assign_instructor(user, section, role, allowed_to_edit_content)
    create(
      :section_instructor,
      allowed_to_edit_content: allowed_to_edit_content,
      instructor: user,
      role: SectionInstructor::INSTRUCTOR_ROLES[role],
      section: section
    )
  end

  describe '#editing_instructor?' do
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course) }
    let(:section_1) { create(:section, course: course, instructor: course.owner) }
    let(:section_2) { create(:section, course: course, instructor: course.owner) }

    it 'is true when the specified user is a co-instructor for and allowed ' \
       'to edit content for all sections in the course' do
      assign_instructor(instructor, section_1, :co_instructor, true)
      assign_instructor(instructor, section_2, :co_instructor, true)

      expect(described_class.new(course, instructor)).to be_editing_instructor
    end

    it 'is true when the specified user is a co-instructor for all sections ' \
       'and allowed to edit content for any section of the course' do
      assign_instructor(instructor, section_1, :co_instructor, true)
      assign_instructor(instructor, section_2, :co_instructor, false)

      expect(described_class.new(course, instructor)).to be_editing_instructor
    end

    it 'is true when the specified user is a co-instructor for any section ' \
       'and allowed to edit content for that section' do
      assign_instructor(instructor, section_1, :co_instructor, true)

      expect(described_class.new(course, instructor)).to be_editing_instructor
    end

    it 'is false when the specified user is a co-instructor on all sections ' \
       'of the course but not allowed to edit content on any section' do
      assign_instructor(instructor, section_1, :co_instructor, false)
      assign_instructor(instructor, section_2, :co_instructor, false)

      expect(described_class.new(course, instructor)).not_to be_editing_instructor
    end

    it 'is true when the specified user is the course owner' do
      expect(described_class.new(course, course.owner)).to be_editing_instructor
    end

    it 'is false if the specified user is not a co-instructor of any ' \
       'section of the course, even if the allowed_to_edit_content flag is ' \
       'set to true' do
      assign_instructor(instructor, section_1, :assistant, true)

      expect(described_class.new(course, instructor)).not_to be_editing_instructor
    end
  end

  describe '#course_owner?' do
    let(:course) { create(:course) }

    context 'when given a user that is not the owner' do
      let(:non_owner) { create(:user) }
      let(:policy) { described_class.new(course, non_owner) }

      it 'returns false' do
        expect(policy).not_to be_course_owner
      end
    end

    context 'when given a user that is the owner of the course' do
      let(:policy) { described_class.new(course, course.owner) }

      it 'returns true' do
        expect(policy).to be_course_owner
      end
    end
  end
end

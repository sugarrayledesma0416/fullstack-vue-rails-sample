describe Services::PubnubOpenCourses do
  let(:instructor) { create(:instructor) }

  # Helper to fetch visible course IDs for the given (optional) base scope
  def visible_course_ids(base: nil)
    described_class.new(instructor, base).eligible_courses.pluck(:id)
  end

  describe '#eligible_courses' do
    context 'when a course has no sections' do
      it 'includes the course' do
        course = create(:open_course, owner: instructor)

        expect(visible_course_ids).to include(course.id)
      end
    end

    context 'when the owner is archived' do
      it 'includes the course' do
        instructor.update!(archived: true)
        course = create(:open_course, owner: instructor)

        expect(visible_course_ids).to include(course.id)
      end
    end

    context 'when the instructor has no section_instructor record for eligible sections' do
      it 'includes the course' do
        course = create(:open_course, owner: instructor)
        other_instructor = create(:instructor)
        create(:section, course:, instructor: other_instructor)

        expect(visible_course_ids).to include(course.id)
      end
    end

    context 'when at least one eligible section is visible' do
      it 'includes the course' do
        course = create(:open_course, owner: instructor)
        section_1 = create(:section, course:, instructor:)
        section_2 = create(:section, course:, instructor:)

        section_1_si = section_1.section_instructors.find_by(user_id: instructor.id)
        section_2_si = section_2.section_instructors.find_by(user_id: instructor.id)
        section_1_si.update!(hide_from_instructor_dashboard: true)
        section_2_si.update!(hide_from_instructor_dashboard: false)

        expect(visible_course_ids).to include(course.id)
      end
    end

    context 'when every eligible section is hidden for this instructor' do
      it 'excludes the course' do
        course = create(:open_course, owner: instructor)
        section_1 = create(:section, course:, instructor:)
        section_2 = create(:section, course:, instructor:)

        section_1_si = section_1.section_instructors.find_by(user_id: instructor.id)
        section_2_si = section_2.section_instructors.find_by(user_id: instructor.id)
        section_1_si.update!(hide_from_instructor_dashboard: true)
        section_2_si.update!(hide_from_instructor_dashboard: true)

        expect(visible_course_ids).not_to include(course.id)
      end
    end

    context 'when only enterprise sections exist' do
      it 'treats this as having no eligible sections and includes the course' do
        course = create(:enterprise_course, owner: instructor)
        create(:enterprise_section, course:, instructor:)

        expect(visible_course_ids).to include(course.id)
      end
    end

    context 'when only archived sections exist' do
      it 'treats this as having no eligible sections and includes the course' do
        course = create(:open_course, owner: instructor)
        archived_section = create(:section, course:, instructor:, is_archived: true)
        archived_section
          .section_instructors
          .find_by(user_id: instructor.id)
          &.update!(hide_from_instructor_dashboard: true)

        expect(visible_course_ids).to include(course.id)
      end
    end

    context 'when SectionInstructor records are archived' do
      it 'does not allow archived SectionInstructor records to hide the course' do
        course = create(:open_course, owner: instructor)
        section = create(:section, course:, instructor:)
        si = section.section_instructors.find_by(user_id: instructor.id)
        si.update!(is_archived: true, hide_from_instructor_dashboard: true)

        expect(visible_course_ids).to include(course.id)
      end
    end
  end
end

describe Support::CourseOwnerPresenter do
  let(:program_1) { create(:program) }
  let(:program_2) { create(:program) }
  let(:school_1) { create(:school) }
  let(:school_2) { create(:school) }
  let(:instructor) { create(:clever_instructor, schools: [school_1, school_2]) }
  let(:open_course_1) { create(:open_course, program: program_1, owner: instructor) }
  let(:open_course_2) { create(:open_course, program: program_1, owner: instructor) }
  let(:open_course_3) { create(:open_course, program: program_2, owner: instructor) }
  let(:open_course_4) { create(:open_course, program: program_2, owner: instructor) }
  let!(:open_courses) do
    [open_course_1, open_course_2, open_course_3, open_course_4]
  end
  let(:presenter) { described_class.new(instructor) }

  describe '#instructor_username' do
    context 'when the instructor is a clever instructor' do
      it 'returns the instructor username' do
        expect(presenter.instructor_username).to eq(instructor.username)
      end
    end

    context 'when the instructor is a RA instructor' do
      let(:instructor) { create(:one_roster_instructor) }

      it 'returns the external username' do
        user_link = create(:one_roster_linked_user, user: instructor)

        expect(presenter.instructor_username).to eq(user_link.external_username)
      end
    end
  end

  describe '#courses' do
    it 'returns all the open courses of the instructor' do
      expect(presenter.courses).to match_array(open_courses)
    end

    it 'does not return closed courses' do
      create(:closed_course, program: program_1, owner: instructor)

      expect(presenter.courses).to match_array(open_courses)
    end

    it 'does not return archived courses' do
      create(:course, program: program_1, owner: instructor, is_archived: true)

      expect(presenter.courses).to match_array(open_courses)
    end

    it 'does not return open courses of other instructors' do
      other_instructor = create(:clever_instructor)
      create(:open_course, program: program_1, owner: other_instructor)

      expect(presenter.courses).to match_array(open_courses)
    end

    it 'returns an empty array when the instrutor has no open course' do
      instructor = create(:clever_instructor)
      presenter = described_class.new(instructor)

      expect(presenter.courses).to eq([])
    end
  end

  describe '#courses_by_program' do
    it 'returns all the open courses of the instructor grouped by program' do
      expect(presenter.courses_by_program).to match_array(
        program_1 => a_collection_containing_exactly(open_course_1, open_course_2),
        program_2 => a_collection_containing_exactly(open_course_3, open_course_4)
      )
    end
  end

  describe '#possible_owners_by_course' do
    let(:instructor_1) { create(:clever_instructor, schools: [school_1]) }
    let(:instructor_2) { create(:clever_instructor, schools: [school_1]) }
    let(:instructor_3) { create(:clever_instructor, schools: [school_1]) }
    let(:course) { create(:open_course, program: program_1, owner: instructor) }
    let!(:section_1) { create(:section, course: course) }
    let!(:section_2) { create(:section, course: course) }

    it 'returns clever instructors that are in one of the schools the ' \
       'instructor is in' do
      instructor_1 = create(:clever_instructor, schools: [school_1])
      instructor_2 = create(:clever_instructor, schools: [school_1])
      instructor_3 = create(:clever_instructor, schools: [school_2])
      instructor_4 = create(:clever_instructor, schools: [school_1, school_2])
      create(:clever_instructor, schools: [create(:clever_school)])

      expect(presenter.possible_owners_by_course(course)).to contain_exactly(
        instructor_1, instructor_2, instructor_3, instructor_4
      )
    end

    it 'does not return archived clever instructors that are in one of the ' \
       'schools the instructor is in' do
      instructor_1 = create(:clever_instructor, schools: [school_1])
      instructor_2 = create(:clever_instructor, schools: [school_1])
      create(:clever_instructor, schools: [school_1], archived: true)

      expect(presenter.possible_owners_by_course(course)).to contain_exactly(
        instructor_1, instructor_2
      )
    end

    it 'does not return clever admins that are in one of the schools the ' \
       'instructor is in' do
      instructor_1 = create(:clever_instructor, schools: [school_1])
      instructor_2 = create(:clever_instructor, schools: [school_1])
      create(:clever_admin, schools: [school_1])

      expect(presenter.possible_owners_by_course(course)).to contain_exactly(
        instructor_1, instructor_2
      )
    end

    it 'returns an empty array when no clever instructors are in one of the ' \
       'schools the instructor is in' do
      expect(presenter.possible_owners_by_course(course)).to eq([])
    end

    context 'when the course owner is an LTI Rostering instructor' do
      it 'returns LTI Rostering instructors that are in one of the schools the ' \
         'course owner is in' do
        program_1 = create(:program)
        instructor = create(:lti_rostering_instructor, schools: [school_1, school_2])
        create(:lti_rostering_user_link, user: instructor)
        instructor_2 = create(:lti_rostering_instructor, schools: [school_1])
        create(:lti_rostering_user_link, user: instructor_2)
        instructor_3 = create(:lti_rostering_instructor, schools: [school_2])
        create(:lti_rostering_user_link, user: instructor_3)
        course = create(:open_course, program: program_1, owner: instructor)
        presenter = described_class.new(instructor)

        expect(presenter.possible_owners_by_course(course)).to contain_exactly(
          instructor_2, instructor_3
        )
      end
    end
  end
end

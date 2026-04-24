describe CourseOwnerUpdater do
  let(:program) { create(:program) }
  let(:schools) do
    [
      create(:clever_school),
      create(:clever_school)
    ]
  end
  let(:previous_owner) { create(:clever_instructor, schools: schools) }
  let(:new_owner) { create(:clever_instructor, schools: [schools.last]) }
  let(:course) { create(:open_course, program: program, owner: previous_owner) }
  let(:section_1) do
    create(
      :section,
      name: 'section 1',
      course: course,
      instructor: previous_owner
    )
  end
  let(:section_2) do
    create(
      :section,
      name: 'section 2',
      course: course,
      instructor: previous_owner
    )
  end
  let(:sections) do
    [
      section_1,
      section_2
    ]
  end
  let(:section_1_previous_owner) do
    SectionInstructor.find_by!(section: section_1, instructor: previous_owner)
  end
  let(:section_2_previous_owner) do
    SectionInstructor.find_by!(section: section_2, instructor: previous_owner)
  end
  let(:section_1_different_instructor) do
    create(
      :section_co_instructor,
      section: section_1,
      instructor: create(:clever_instructor)
    )
  end
  let!(:section_instructors) do
    [
      section_1_previous_owner,
      section_2_previous_owner,
      section_1_different_instructor
    ]
  end
  let(:updater) { described_class.new(course, new_owner) }
  let(:lti_rostering_schools) do
    create_list(:school, 2)
  end
  let(:lti_rostering_previous_owner) do
    user = create(:lti_rostering_instructor, schools: lti_rostering_schools)
    create(:lti_rostering_user_link, user: user)
    user
  end
  let(:lti_rostering_new_owner) do
    user = create(:lti_rostering_instructor, schools: [lti_rostering_schools.last])
    create(:lti_rostering_user_link, user: user)
    user
  end
  let(:ra_schools) do
      create_list(:one_roster_school, 2)
  end
  let(:ra_previous_owner) do
    user = create(:one_roster_instructor, schools: ra_schools)
    create(:one_roster_linked_user, user: user, school: ra_schools.last)
    user
  end
  let(:ra_new_owner) do
    user = create(:one_roster_instructor, schools: [ra_schools.last])
    create(:one_roster_linked_user, user: user, school: ra_schools.last)
    user
  end

  describe '#update' do
    context 'when the course transfer is between Clever instructors' do
      context 'when the previous owner is not a Clever instructor' do
        let(:previous_owner) { create(:instructor) }

        it_behaves_like 'a previous owner that is not a valid instructor'
      end

      context 'when the new owner is not a Clever instructor' do
        let(:new_owner) { create(:instructor) }

        it_behaves_like 'a new owner that is not a valid instructor'
      end

      context 'when the new owner is not in one of the schools the current owner ' \
              'belongs to' do
        let(:new_owner) do
          create(:clever_instructor, schools: [create(:clever_school)])
        end

        it_behaves_like 'a new owner that is not in one of the schools ' \
                        'the current owner belongs to'
      end

      context 'when the new owner is a Clever instructor in one of the schools ' \
              'the current owner belongs to' do

        it_behaves_like 'a new owner that is a valid instructor in one of the schools ' \
                        'the current owner belongs to'

        context 'when the new owner is co-instructor in a section of the course' do
          it_behaves_like 'a new owner that is co-instructor in a section of the course'
        end
      end

      context 'when the previous and new owner have different instructor types.' do
        let(:new_owner) { lti_rostering_new_owner }

        it_behaves_like 'a previous and new owner that have different instructor types.'
      end

      context 'when the course is closed' do
        let(:course) do
          create(:closed_course, program: program, owner: previous_owner)
        end

        it_behaves_like 'a course that is closed'
      end

      context 'when the course is closed but editable' do
        let(:course) do
          create(:editable_course, program: program, owner: previous_owner)
        end

        it_behaves_like 'a course that is closed but editable'
      end

      context 'when the course is archived' do
        let(:course) do
          create(:archived_course, program: program, owner: previous_owner)
        end

        it_behaves_like 'a course that is archived'
      end
    end

    context 'when the course transfer is between LTI Rostering instructors' do
      let(:previous_owner) { lti_rostering_previous_owner }
      let(:new_owner) { lti_rostering_new_owner }

      context 'when the previous owner is not an LTI Rostering instructor' do
        let(:previous_owner) { create(:instructor) }

        it_behaves_like 'a previous owner that is not a valid instructor'
      end

      context 'when the new owner is not an LTI Rostering instructor' do
        let(:new_owner) { create(:instructor) }

        it_behaves_like 'a new owner that is not a valid instructor'
      end

      context 'when the new owner is an LTI Rostering instructor in a ' \
              'school the current owner does not belong to' do
        let(:new_owner) do
          user = create(:lti_rostering_instructor, schools: [create(:school)])
          create(:lti_rostering_user_link, user: user)
          user
        end

        it_behaves_like 'a new owner that is not in one of the schools ' \
                        'the current owner belongs to'
      end

      context 'when the new owner is an LTI Rostering instructor in one of the schools ' \
              'the current owner belongs to' do
        it_behaves_like 'a new owner that is a valid instructor in one of the schools ' \
                        'the current owner belongs to'

        context 'when the new owner is co-instructor in a section of the course' do
          it_behaves_like 'a new owner that is co-instructor in a section of the course'
        end
      end
    end

    context 'when the course transfer is between Roster Assistant instructors' do
      let(:previous_owner) { ra_previous_owner }
      let(:new_owner) { ra_new_owner }

      context 'when the previous owner is not a Roster Assistant instructor' do
        let(:previous_owner) { create(:instructor) }

        it_behaves_like 'a previous owner that is not a valid instructor'
      end

      context 'when the new owner is not a Roster Assistant instructor' do
        let(:new_owner) { create(:instructor) }

        it_behaves_like 'a new owner that is not a valid instructor'
      end

      context 'when the new owner is a Roster Assistant instructor in a ' \
              'school the current owner does not belong to' do
        let(:new_owner) do
          external_ra_school = create(:one_roster_school)
          user = create(:one_roster_instructor, schools: [external_ra_school])
          create(:one_roster_linked_user, user: user, school: external_ra_school)
          user
        end

        it_behaves_like 'a new owner that is not in one of the schools ' \
                        'the current owner belongs to'
      end

      context 'when the new owner is a Roster Assistant instructor in one of the schools ' \
              'the current owner belongs to' do
        it_behaves_like 'a new owner that is a valid instructor in one of the schools ' \
                        'the current owner belongs to'

        context 'when the new owner is co-instructor in a section of the course' do
          it_behaves_like 'a new owner that is co-instructor in a section of the course'
        end
      end
    end
  end
end

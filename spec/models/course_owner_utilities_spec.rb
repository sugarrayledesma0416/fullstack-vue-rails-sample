describe CourseOwnerUtilities do
  let(:clever_school) { create(:clever_school) }
  let(:other_clever_school) { create(:clever_school) }
  let(:clever_instructor) do
    user = create(:clever_instructor, schools: [clever_school])
    user.extend(described_class)
  end
  let(:fellow_clever_instructor) do
    user = create(:clever_instructor, schools: [clever_school])
    user.extend(described_class)
  end
  let(:external_clever_instructor) do
    user = create(:clever_instructor, schools: [other_clever_school])
    user.extend(described_class)
  end
  let(:lti_rostering_school) { create(:school) }
  let(:other_lti_rostering_school) { create(:school) }
  let(:lti_rostering_instructor) do
    user = create(:lti_rostering_instructor, schools: [lti_rostering_school])
    create(:lti_rostering_user_link, user: user)
    user.extend(described_class)
  end
  let(:fellow_lti_rostering_instructor) do
    user = create(:lti_rostering_instructor, schools: [lti_rostering_school])
    create(:lti_rostering_user_link, user: user)
    user.extend(described_class)
  end
  let(:external_lti_rostering_instructor) do
    user = create(:lti_rostering_instructor, schools: [other_lti_rostering_school])
    create(:lti_rostering_user_link, user: user)
    user.extend(described_class)
  end
  let(:vhl_instructor) do
    user = create(:instructor)
    user.extend(described_class)
  end
  let(:ra_school) { create(:one_roster_school) }
  let(:other_ra_school) { create(:one_roster_school) }
  let(:ra_instructor) do
    user = create(:one_roster_instructor, schools: [ra_school])
    create(:one_roster_linked_user, user: user, school: ra_school)
    user.extend(described_class)
  end
  let(:fellow_ra_instructor) do
    user = create(:one_roster_instructor, schools: [ra_school])
    create(:one_roster_linked_user, user: user, school: ra_school)
    user.extend(described_class)
  end
  let(:external_ra_instructor) do
    user = create(:one_roster_instructor, schools: [ra_school])
    create(:one_roster_linked_user, user: user, school: other_ra_school)
  end
  let(:ra_instructor_with_lti_user_link) do
    user = create(:one_roster_instructor, schools: [ra_school])
    create(:one_roster_linked_user, user: user, school: ra_school)
    create(:lti_rostering_user_link, user: user)
    user.extend(described_class)
  end

  let(:clever_instructor_with_lti_user_link) do
    user = create(:clever_instructor, schools: [clever_school])
    create(:lti_rostering_user_link, user: user)
    user.extend(described_class)
  end

  describe '#allows_rostering_course_transfer?' do
    it 'returns true for Clever instructors' do
      expect(clever_instructor.allows_rostering_course_transfer?).to be true
    end

    it 'returns true for LTI Rostering Instructors' do
      expect(lti_rostering_instructor.allows_rostering_course_transfer?).to be true
    end

    it 'returns true for Roster Assistant Instructors' do
      expect(ra_instructor.allows_rostering_course_transfer?).to be true
    end

    it 'returns false for VHL instructors' do
      expect(vhl_instructor.allows_rostering_course_transfer?).to be false
    end
  end

  describe '#other_instructor_same_type?' do
    it 'returns true comparing Clever instructors' do
      expect(
        clever_instructor.other_instructor_same_type?(fellow_clever_instructor)
      ).to be true
    end

    it 'returns false comparing a Clever instructor with an LTI Rostering instructor' do
      expect(
        clever_instructor.other_instructor_same_type?(lti_rostering_instructor)
      ).to be false
    end

    it 'returns false comparing a Clever instructor with a Roster Assistant instructor' do
      expect(
        clever_instructor.other_instructor_same_type?(ra_instructor)
      ).to be false
    end

    it 'returns false comparing a Clever instructor with a VHL instructor' do
      expect(
        clever_instructor.other_instructor_same_type?(vhl_instructor)
      ).to be false
    end

    it 'returns true comparing LTI Rostering instructors' do
      expect(
        lti_rostering_instructor.other_instructor_same_type?(fellow_lti_rostering_instructor)
      ).to be true
    end

    it 'returns false comparing an LTI Rostering instructor with a VHL instructor' do
      expect(
        lti_rostering_instructor.other_instructor_same_type?(vhl_instructor)
      ).to be false
    end

    it 'returns false comparing an LTI Rostering instructor with a RA instructor' do
      expect(
        lti_rostering_instructor.other_instructor_same_type?(ra_instructor)
      ).to be false
    end

    it 'returns true comparing Roster Assistant instructors' do
      expect(
        ra_instructor.other_instructor_same_type?(fellow_ra_instructor)
      ).to be true
    end

    it 'returns false comparing a Roster Assistant instructor with a VHL instructor' do
      expect(
        ra_instructor.other_instructor_same_type?(vhl_instructor)
      ).to be false
    end
  end

  describe '#instructor_type' do
    it 'returns Clever for Clever instructors' do
      expect(
        clever_instructor.instructor_type
      ).to eq('Clever')
    end

    it 'returns LTI Rostering for LTI Rostering instructors' do
      expect(
        lti_rostering_instructor.instructor_type
      ).to eq('LTI Rostering')
    end

    it 'returns Roster Assistant for Roster Assistant instructors' do
      expect(
        ra_instructor.instructor_type
      ).to eq('Roster Assistant')
    end

    it 'returns nil for other types of instructors' do
      expect(
        vhl_instructor.instructor_type
      ).to be_nil
    end
  end

  describe '#same_type_instructors_in_school' do
    before do
      fellow_clever_instructor
      external_clever_instructor
      fellow_lti_rostering_instructor
      external_lti_rostering_instructor
      fellow_ra_instructor
      external_ra_instructor
      ra_instructor_with_lti_user_link
    end

    context 'when the user is a Clever instructor' do
      it 'returns other Clever instructors from the same school' do
        expect(
          clever_instructor.same_type_instructors_in_school
        ).to include(fellow_clever_instructor)
      end

      it 'does not return Clever instructors from other school' do
        expect(
          clever_instructor.same_type_instructors_in_school
        ).not_to include(external_clever_instructor)
      end

      it 'does not return different type instructors from the same school' do
        vhl_instructor = create(:instructor, schools: [clever_school])

        expect(
          clever_instructor.same_type_instructors_in_school
        ).not_to include(vhl_instructor)
      end
    end

    context 'when the user is an LTI Rostering instructor ' do
      it 'returns other LTI Rostering instructors from the same school' do
        expect(
          lti_rostering_instructor.same_type_instructors_in_school
        ).to include(fellow_lti_rostering_instructor)
      end

      it 'does not return LTI Rostering instructors from other school' do
        expect(
          lti_rostering_instructor.same_type_instructors_in_school
        ).not_to include(external_lti_rostering_instructor)
      end

      it 'does not return different type instructors from the same school' do
        vhl_instructor = create(:instructor, schools: [lti_rostering_school])

        expect(
          lti_rostering_instructor.same_type_instructors_in_school
        ).not_to include(vhl_instructor)
      end
    end

    context 'when the user is a Roster Assistant instructor ' do
      it 'returns other Roster Assistant instructors from the same school' do
        expect(
          ra_instructor.same_type_instructors_in_school
        ).to include(fellow_ra_instructor)
      end

      it 'does not return Roster Assistant instructors from other school' do
        expect(
          ra_instructor.same_type_instructors_in_school
        ).not_to include(external_ra_instructor)
      end

      it 'does not return different type instructors from the same school' do
        vhl_instructor = create(:instructor, schools: [ra_school])

        expect(
          ra_instructor.same_type_instructors_in_school
        ).not_to include(vhl_instructor)
      end

      it 'does not return Roster Assistant instructors with LTI Rostering link' do

        expect(
          ra_instructor.same_type_instructors_in_school
        ).not_to include(ra_instructor_with_lti_user_link)
      end
    end
  end

  describe '#lti_rostering_instructor?' do
    it 'returns false for Clever students' do
      user = create(:clever_student, schools: [clever_school])
      user.extend(described_class)

      expect(user).not_to be_lti_rostering_instructor
    end

    it 'returns false for Clever admins' do
      user = create(:clever_admin, schools: [clever_school])
      user.extend(described_class)

      expect(user).not_to be_lti_rostering_instructor
    end

    it 'returns true for LTI Rostering instructors' do
      expect(lti_rostering_instructor).to be_lti_rostering_instructor
    end

    it 'returns false for VHL instructors' do
      user = create(:instructor)
      user.extend(described_class)

      expect(user).not_to be_lti_rostering_instructor
    end

    context 'when instructor was transitioned from Clever to LTI Rostering' do
      it 'no longer recognizes instructor as a Clever instructor' do
        expect(clever_instructor_with_lti_user_link).not_to be_clever_instructor
      end

      it 'recognizes instructor as an LTI Rostering instructor' do
        expect(clever_instructor_with_lti_user_link).to be_lti_rostering_instructor
      end
    end
  end

  describe '#ra_instructor?' do
    it 'returns true for RA instructors' do
      expect(ra_instructor).to be_ra_instructor
    end

    it 'returns false for RA students' do
      user = create(:one_roster_user, schools: [ra_school])
      user.extend(described_class)
      create(:one_roster_linked_user, user: user, school: ra_school)

      expect(user).not_to be_ra_instructor
    end

    it 'returns false for VHL instructors' do
      expect(vhl_instructor).not_to be_ra_instructor
    end

    it 'returns false for Clever admins' do
      user = create(:clever_admin)
      user.extend(described_class)

      expect(user).not_to be_ra_instructor
    end

    it 'returns false for Clever students' do
      user = create(:clever_student)
      user.extend(described_class)

      expect(user).not_to be_ra_instructor
    end

    it 'returns false for Clever instructors' do
      expect(clever_instructor).not_to be_ra_instructor
    end

    it 'returns false for LTI Rostering instructors' do
      expect(lti_rostering_instructor).not_to be_ra_instructor
    end

    it 'returns false for LTI Rostering instructors who were transitioned from RA' do
      expect(ra_instructor_with_lti_user_link).not_to be_ra_instructor
    end
  end
end

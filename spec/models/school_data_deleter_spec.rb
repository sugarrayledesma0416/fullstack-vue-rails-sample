describe SchoolDataDeleter do
  let(:school) { create(:school) }
  let(:other_school) { create(:school) }
  let(:deleter) { described_class.new(school.id) }

  describe '#delete_school_data' do
    before do
      allow(GradebookEngine::GradebookAPI).to receive(:delete_school_data)
      allow_any_instance_of(Lossless::Client).to(
        receive(:delete_school_data).and_return(true)
      )
    end

    it 'deletes all courses associated with the school' do
      course = create(:course, school: school)
      expect(CourseDataDeleter).to receive(:new).with(course.id).and_call_original
      allow_any_instance_of(CourseDataDeleter).to receive(:delete_course_data)
      deleter.delete_school_data
    end

    it 'deletes shared library activities associated with the school' do
      allow(Maestro::LicenseGroup).to receive(:all).and_return([])
      program = create(:program)
      strand = create(:toc_entry)
      unit = create(:unit, program: program)
      lesson = create(:lesson, toc_entries: [strand], unit: unit)
      concept = create(:concept,
                       lesson: lesson,
                       program: program,
                       id: strand.location)
      activity = create(:instructor_created_activity,
                        lesson: lesson,
                        toc_entry_id: strand.location)
      create(:shared_library_activity,
             school: school,
             source_activity: activity)
      create(:shared_library_activity,
             school: other_school,
             source_activity: activity)
      deleter.delete_school_data
      expect(SharedLibraryActivity.where(school_id: school.id)).to be_empty
      expect(SharedLibraryActivity.where(school_id: other_school.id)).to_not be_empty
    end

    it 'deletes all school-user records associated with the school' do
      create(:school_user, school: school)
      create(:school_user, school: other_school)
      allow_any_instance_of(UserDataDeleter).to receive(:delete_user_data)
      deleter.delete_school_data
      expect(SchoolUser.where(school_id: school.id)).to be_empty
      expect(SchoolUser.where(school_id: other_school.id)).to_not be_empty
    end

    it 'deletes users associated with the school' do
      user_1 = create(:user)
      user_2 = create(:user)
      create(:school_user, user: user_1, school: school)
      create(:school_user, user: user_2, school: other_school)
      expect(UserDataDeleter).to(
        receive(:new).with(user_1.id, school_id: school.id).and_call_original
      )
      allow_any_instance_of(UserDataDeleter).to receive(:delete_user_data)
      deleter.delete_school_data
      expect(User.find_by(id: user_2.id)).to_not be_nil
    end

    it 'deletes grades' do
      expect(GradebookEngine::GradebookAPI).to receive(:delete_school_data).with(school.id)
      deleter.delete_school_data
    end

    it 'deletes audio recordings from the lossless service' do
      expect_any_instance_of(Lossless::Client).to(
        receive(:delete_school_data).with(school.id)
      )
      deleter.delete_school_data
    end
  end
end

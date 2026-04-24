describe InstitutionAdminHiddenCourse do
  describe '.hide_courses' do
    let(:admin) { create(:institution_admin) }
    let(:school) { create(:school) }
    let(:program) { create(:program) }
    let(:other_program) { create(:program) }
    let!(:program_config) { create(:program_config, program: program) }

    let!(:school_program_admin_user) do
      create(:school_program_admin_user, user: admin,
                                        school: school,
                                        program: program,
                                        account_type: admin.account_type)
    end

    it 'adds records for courses in the program not already hidden' do
      courses = create_list(:course, 2, program: program, school: school)

      # hide the first course
      described_class.create(course_id: courses[0].id, program_id: program.id, user_id: admin.id)
      # call method to hide both courses
      course_ids_to_hide = courses.map(&:id)
      described_class.hide_courses(admin, program, course_ids_to_hide)

      hidden_course_ids = described_class
        .where(program_id: program.id, user_id: admin.id)
        .pluck(:course_id)

      expect(hidden_course_ids).to eq(course_ids_to_hide)
    end

    it 'removes records for courses in the program no longer hidden' do
      courses = create_list(:course, 2, program: program, school: school)

      # hide the first course
      described_class.create(course_id: courses[0].id, program_id: program.id, user_id: admin.id)
      # call method to hide only the second course
      course_ids_to_hide = [courses[1].id]
      described_class.hide_courses(admin, program, course_ids_to_hide)

      hidden_course_ids = described_class
        .where(program_id: program.id, user_id: admin.id)
        .pluck(:course_id)

      expect(hidden_course_ids).to eq(course_ids_to_hide)
    end

    it 'does not add records for courses to be hidden if they are not in the program' do
      courses = create_list(:course, 2, program: program, school: school)
      course_in_other_program = create(:course, program: other_program, school: school)

      # call method to hide courses in program plus course in other program
      course_ids_to_hide = [*courses.map(&:id), course_in_other_program.id]
      described_class.hide_courses(admin, program, course_ids_to_hide)

      hidden_course_ids = described_class
        .where(program_id: program.id, user_id: admin.id)
        .pluck(:course_id)

      expect(hidden_course_ids).to eq(courses.map(&:id))
    end

    it 'does not remove records for courses that are not in the program' do
      courses = create_list(:course, 2, program: program, school: school)
      course_in_other_program = create(:course, program: other_program, school: school)

      described_class.create(course_id: course_in_other_program.id, program_id: other_program.id, user_id: admin.id)

      # call method to hide only the courses in the program
      course_ids_to_hide = courses.map(&:id)
      described_class.hide_courses(admin, program, course_ids_to_hide)

      hidden_courses = described_class.where(course_id: course_in_other_program.id, program_id: other_program.id, user_id: admin.id)

      expect(hidden_courses).not_to be_empty
    end
  end
end

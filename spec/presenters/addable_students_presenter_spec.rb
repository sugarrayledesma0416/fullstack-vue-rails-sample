describe AddableStudentsPresenter do
  let(:instructor) { create(:instructor) }
  let(:program) { build_stubbed(:program) }
  let(:section) { build_stubbed(:section) }
  let(:student_1) { create(:student, last_name: 'Able') }
  let(:student_2) { create(:student, last_name: 'Baker') }
  let(:school) { create(:school) }

  before do
    create(:school_user, user_id: instructor.id, school_id: school.id)
    create(:school_user, user_id: student_1.id, school_id: school.id)
    create(:school_user, user_id: student_2.id, school_id: school.id)
  end

  describe '#students' do
    context 'when searching by email, ' do
      it 'looks up the student by email and ensures he is not fake' do
        email = student_1.email

        presenter = described_class.new(
          instructor.schools, program,
          return_to: 'something/something',
          search_str: email,
          section_id: section.id
        )
        expect(presenter.students.to_a).to eq [student_1]
      end

      it 'looks up the student by first or last name' do
        search_str = "#{student_1.first_name} #{student_2.last_name}"

        presenter = described_class.new(
          instructor.schools, program,
          return_to: 'something/something',
          search_str: search_str,
          section_id: section.id
        )
        expect(presenter.students.to_a).to eq [student_1, student_2]
      end

      it 'looks for students that are in the provided school(s)' do
        search_str = student_1.last_name
        student_3 = create(:student, last_name: student_1.last_name)
        school_2 = create(:school)
        create(:school_user, user_id: student_3.id, school_id: school_2.id)
        expect(Student.count).to eq 3
        expect(SchoolUser.count).to eq 4 # 3 students, 1 instructor

        presenter = described_class.new(
          instructor.schools, program,
          return_to: 'something/something',
          search_str: search_str,
          section_id: section.id
        )
        expect(presenter.students.to_a).to eq [student_1]
      end
    end

    context 'when searching for a student ' do
      it 'does not return any student that is a roster assistant user' do
        student_3 = create(:one_roster_student, last_name: student_2.last_name)
        create(:one_roster_linked_user, user: student_3)
        create(:school_user, user_id: student_3.id, school_id: school.id)
        search_str = "#{student_1.first_name} #{student_2.last_name}"

        presenter = described_class.new(
          instructor.schools, program,
          return_to: 'something/something',
          search_str: search_str,
          section_id: section.id
        )
        expect(presenter.students.to_a).to eq [student_1, student_2]
      end
    end
  end

  describe '#active_enrollments_for_student' do
    let(:course) { create(:course, start_date: 1.week.ago, end_date: 3.weeks.from_now) }
    let(:section_2) { create(:section, course_id: course.id) }
    let!(:enrollment) do
      create(:enrollment, user_id: student_1.id,
                          section_id: section_2.id,
                          state: 'enrolled')
    end

    it 'returns an array of enrollments for a student' do
      presenter = described_class.new(
        school, program,
        return_to: 'something/something',
        search_str: student_1.email,
        section_id: section_2.id
      )
      expect(presenter.active_enrollments_for_student(student_1)).to eq [enrollment]
    end
  end
end

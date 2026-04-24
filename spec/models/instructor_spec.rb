describe Instructor do

  before(:each) do
    @school = build_stubbed(:school)
    @program = build_stubbed(:program)
  end

  describe "named_scopes" do
    describe ".by_school" do
      before do
        @instructor = create(:instructor)
        @instructor_not_in_school = create(:instructor)
        create(:school_user, :user => @instructor, :school => @school)
      end

      it 'returns all instructors in school' do
        expect(Instructor.by_school(@school)).to eq([@instructor])
      end
    end
  end

  describe '#courses' do
    let(:instructor) { create(:instructor) }

    it 'returns courses the instructor owns' do
      course = create(
        :course,
        owner: instructor,
        school: @school,
        program: @program
      )
      expect(instructor.reload.courses).to include course
    end

    it 'does not return archived courses' do
      course = create(
        :course,
        owner: instructor,
        is_archived: true,
        school: @school,
        program: @program
      )
      expect(instructor.reload.courses).to be_empty
    end

    it 'does not return course templates' do
      course = create(:course,
                      is_template: true,
                      owner: instructor,
                      program: @program,
                      school: @school)
      expect(instructor.reload.courses).to be_empty
    end
  end

  describe "#has_any_course_for" do
    before(:each) do
      @instructor = create(:instructor)
      @co_instructor = create(:instructor)
    end

    it "should return true if the instructor has an open course" do
      open_course = create(:open_course, :owner => @instructor, :school => @school, :program => @program)
      expect(@instructor.has_any_course_for?(@program)).to be_truthy
    end

    it "should return true if the instructor has a closed course" do
      closed_course = create(:closed_course, :owner => @instructor, :school => @school, :program => @program)
      expect(@instructor.has_any_course_for?(@program)).to be_truthy
    end

    it "returns true if the co-instructor has any courses for the specified program" do
      open_course = create(:open_course, :owner => @instructor, :school => @school, :program => @program)
      section = create(:section, :instructor => @co_instructor, course: open_course)
      expect(@co_instructor.has_any_course_for?(@program)).to be_truthy
    end

    it "should return false if the instructor has no courses" do
      expect(@instructor.has_any_course_for?(@program)).to be_falsey
    end
  end

  describe '#open_courses' do
    let(:instructor) { create(:instructor) }
    let(:school) { create(:school) }
    let(:program) { create(:program) }
    let!(:course) { create(:course, owner: instructor, school:, program:) }

    it 'returns instructor owned courses' do
      expect(instructor.open_courses).to include(course)
    end

    it 'excludes archived courses' do
      archived_course = create(:course, owner: instructor, school:, program:, is_archived: true)
      expect(instructor.open_courses).not_to include(archived_course)
    end

    it 'returns only currently open courses' do
      future_course = create(
        :course,
        owner: instructor,
        school:,
        program:,
        end_date: 5.days.from_now
      )
      expect(instructor.open_courses).to include(future_course)
    end
  end

  describe '#courses with associations' do
    let(:instructor) { create(:instructor) }
    let(:school) { create(:school) }
    let(:program) { create(:program) }
    let!(:course) do
      create(
        :course,
        owner: instructor,
        school:,
        program:,
        is_demo: false,
        draft: false
      )
    end
    let!(:demo_course) do
      create(
        :course,
        owner: instructor,
        school:,
        program:,
        is_demo: true,
        draft: false
      )
    end

    context 'with eager loading' do
      let(:loaded_course) { instructor.open_courses.first }

      it 'loads program associations' do
        expect(loaded_course.association(:program)).to be_loaded
      end
    end

    context 'when filtering open courses' do
      it 'excludes demo courses' do
        expect(instructor.open_courses).not_to include(demo_course)
      end

      it 'excludes draft courses' do
        demo_course.update(draft: true)
        expect(instructor.open_courses).not_to include(demo_course)
      end
    end

    context 'when chaining the courses scope' do
      it 'chains with open_course scope' do
        future_course = create(
          :course,
          owner: instructor,
          school:,
          program:,
          end_date: 5.days.from_now
        )
        result = instructor.open_courses

        expect(result).to include(future_course)
      end

      it 'returns courses that can be further queried' do
        expect(instructor.open_courses).to respond_to(:each)
      end

      it 'maintains ordering' do
        create(
          :course,
          owner: instructor,
          school:,
          program:,
          name: 'A Course',
          start_date: 1.day.ago
        )
        result = instructor.open_courses
        expect(result.map(&:name)).to eq(['A Course', course.name])
      end
    end
  end

  describe ".build_draft_course" do
    it "creates a new Course object with the default attribute values set" do
      instructor = build_stubbed(:instructor)
      start_unit = double("unit", :id => 1)
      end_unit = double("unit", :id => 2)
      program = double("program", :id => 3, :units => [start_unit, end_unit])
      course = instructor.build_draft_course(program, 5)
      expect(course.owner_id).to eq(instructor.id)
      expect(course.program_id).to eq(program.id)
      expect(course.school_id).to eq(5)
      expect(course.first_unit_id).to eq(start_unit.id)
      expect(course.last_unit_id).to eq(end_unit.id)
      expect(course.name).to eq("New course")
      expect(course.start_date).to eq(Date.current)
      expect(course.end_date).to eq(Date.current + 14.weeks)
      expect(course.draft).to be_truthy
    end
  end

  describe "#find_draft_course" do
    let(:instructor) { build_stubbed(:instructor) }
    let(:course) { create(:course, :owner => instructor) }
    let(:draft_course) { create(:draft_course, :owner => instructor) }

    it "returns a course for the given id" do
      expect(instructor.find_draft_course(draft_course.id)).to eq(draft_course)
    end

    it "returns a course for the given id and adds an error if it is not a draft" do
      result_course = instructor.find_draft_course(course.id)
      expect(result_course.errors.full_messages).to include Course::EXPIRED_MESSAGE
    end
  end

  describe "#find_or_create_draft_course" do
    let(:instructor) { build_stubbed(:instructor) }
    let(:program) { double('program') }

    before do
      allow(instructor).to receive(:find_draft_course)
      allow(instructor).to receive(:new_course_with_default_values)
    end
    it "calls 'find_draft_course' when a course_id is passed" do
      expect(instructor).to receive(:find_draft_course)
      instructor.find_or_create_draft_course(program, 1 , 1)
    end

    it "calls 'new_course_with_default_values' when a course_id is not passed" do
      expect(instructor).to receive(:build_draft_course)
      instructor.find_or_create_draft_course(program, 1)
    end
  end

  describe '#gradeable_sections' do
    it 'returns sections for which the instructor is the instructor, co-instructor or assistant' do
      instructor = create(:instructor)
      section_1 = create(:section)
      section_2 = create(:section)
      section_3 = create(:section)
      create(:section_instructor,
              :instructor => instructor,
              :section => section_1,
              :role => SectionInstructor::INSTRUCTOR_CREATOR_ROLES[:instructor])
      create(:section_instructor,
              :instructor => instructor,
              :section => section_2,
              :role => SectionInstructor::INSTRUCTOR_ROLES[:co_instructor])
      create(:section_instructor,
              :instructor => instructor,
              :section => section_3,
              :role => SectionInstructor::INSTRUCTOR_ROLES[:assistant])
      expect(instructor.gradeable_sections).to match_array([section_1, section_2, section_3])
    end
  end

  describe '#section_can_be_graded?' do
    it 'returns true if the specified section that can be gradeable by the instructor' do
      instructor = create(:instructor)
      section_1 = create(:section)
      section_2 = create(:section)
      section_3 = create(:section)

      create(:section_instructor,
             instructor: instructor,
             section: section_1,
             role: SectionInstructor::INSTRUCTOR_CREATOR_ROLES[:instructor])

      create(:section_instructor,
             instructor: instructor,
             section: section_2,
             role: SectionInstructor::INSTRUCTOR_ROLES[:co_instructor])

      create(:section_instructor,
             instructor: instructor,
             section: section_3,
             role: SectionInstructor::INSTRUCTOR_ROLES[:assistant])

      expect(instructor.section_can_be_graded?(section_1.id)).to be_truthy
      expect(instructor.section_can_be_graded?(section_2.id)).to be_truthy
      expect(instructor.section_can_be_graded?(section_3.id)).to be_truthy
    end

    it 'returns false if the specified section cannot be gradeable by the instructor' do
      instructor = create(:instructor)
      section_1 = create(:section)
      section_2 = create(:section)
      section_3 = create(:section)

      create(:section_instructor,
             instructor: instructor,
             section: section_1,
             role: SectionInstructor::INSTRUCTOR_CREATOR_ROLES[:instructor])

      create(:section_instructor,
             instructor: instructor,
             section: section_2,
             role: SectionInstructor::INSTRUCTOR_ROLES[:co_instructor])

      expect(instructor.section_can_be_graded?(section_1.id)).to be_truthy
      expect(instructor.section_can_be_graded?(section_2.id)).to be_truthy
      expect(instructor.section_can_be_graded?(section_3.id)).to be_falsey
    end
  end

  describe '.courses_by_school' do
    before do
      @instructor = create(:instructor)
      @course = create(:course, :owner => @instructor, :school => @school)
    end

    it 'returns courses for the school' do
      expect(@instructor.courses_by_school(@school)).to eq([@course])
    end
  end

  describe '#closed_courses_by_program_and_year' do
    before do
      @instructor = create(:instructor)
      @program = create(:program)
      other_program = create(:program)

      @closed_course_in_program_and_year = create(:closed_course, {
        :owner => @instructor,
        :program => @program,
        :start_date => Date.parse('2009-06-20'),
        :end_date => Date.parse('2009-06-21') } )

      closed_course_in_program_other_year = create(:closed_course, {
        :owner => @instructor,
        :program => @program,
        :start_date => Date.parse('2008-06-20'),
        :end_date => Date.parse('2009-06-21') } )

      closed_course_other_program_in_year = create(:closed_course, {
        :owner => @instructor,
        :program => other_program,
        :start_date => Date.parse('2009-06-20'),
        :end_date => Date.parse('2009-06-21') } )
    end

    it 'returns closed courses for the program for the year' do
      expect(@instructor.closed_courses_by_program_and_year(@program, 2009)).to eq([@closed_course_in_program_and_year])
    end
  end

  describe '#closed_courses_by_program_and_year_with_owned_sections' do
    it 'returns all closed courses for a given year with the sections that the instructor taught' do
      instructor = create(:instructor)
      instructor2 = create(:instructor)
      program = create(:program)
      closed_course_in_year = create(:closed_course, :program => program, :start_date => Date.new(2010, 1, 1), :end_date => Date.new(2010, 12, 31), :owner => instructor)
      other_closed_course_in_year = create(:closed_course, :program => program, :start_date => Date.new(2010, 2, 1), :end_date => Date.new(2010, 12, 31), :owner => instructor2)
      closed_course_without_section_in_year = create(:closed_course, :program => program, :start_date => Date.new(2010, 2, 1), :end_date => Date.new(2010, 12, 31), :owner => instructor)

      closed_course_in_other_year = create(:closed_course, :program => program, :start_date => Date.new(2011, 1, 1), :end_date => Date.new(2011, 12, 31), :owner => instructor)
      closed_course_in_other_program = create(:closed_course, :start_date => Date.new(2010, 1, 1), :end_date => Date.new(2010, 12, 31), :owner => instructor)
      owned_section_in_year = create(:section, :course => closed_course_in_year, :instructor => instructor)

      other_section_in_year = create(:section, :course => other_closed_course_in_year, :instructor => instructor2)
      create(:section_instructor, :section => other_section_in_year, :user_id => instructor.id) # co-instructor

      expected = {
        closed_course_in_year => [owned_section_in_year],
        other_closed_course_in_year => [other_section_in_year],
        closed_course_without_section_in_year  => []
      }
      expect(instructor.closed_courses_by_program_and_year_with_owned_sections(program, 2010)).to eq(expected)
    end
  end

  context 'given open and closed courses for a school and a program' do
    describe '.open_courses_by_school_and_program', test_debt: true do
      it 'returns open courses by school and program' do
        instructor = create(:instructor)
        school = create(:school)
        program = create(:program)
        course_1 = create(:open_course, :school => school, :program => program, :owner => instructor)
        course_2 = create(:closed_course, :school => school, :program => program, :owner => instructor)
        course_3 = create(:open_course, :school => school, :owner => instructor) # different program
        course_4 = create(:open_course, :program => program, :owner => instructor) # different program
        expect(instructor.open_courses_by_school_and_program(school, program)).to eq [course_1]
      end
    end

    describe '.closed_courses_by_school_and_program' do
      it 'returns closed courses by school and program' do
        instructor = create(:instructor)
        school = create(:school)
        program = create(:program)
        course_1 = create(:closed_course, :school => school, :program => program, :owner => instructor)
        course_2 = create(:open_course, :school => school, :program => program, :owner => instructor)
        course_3 = create(:closed_course, :school => school, :owner => instructor) # different program
        course_4 = create(:closed_course, :program => program, :owner => instructor) # different program
        expect(instructor.closed_courses_by_school_and_program(school, program)).to eq([course_1])
      end
    end
  end

  describe '.editable_courses_by_program' do
    it 'returns all editable courses by program' do
      instructor = create(:instructor)
      program = create(:program)
      course_1 = create(:open_course, program:, owner: instructor)
      course_2 = create(:editable_course, program:, owner: instructor)
      course_3 = create(:closed_course, program:, owner: instructor)
      course_4 = create(:open_course, owner: instructor) # different program
      expect(instructor.editable_courses_by_program(program).to_a).to match_array([course_1, course_2])
    end
  end

  describe '.editable_courses_by_school_and_program' do
    it 'returns all editable courses by school and program' do
      instructor = create(:instructor)
      school = create(:school)
      program = create(:program)
      default_attrs = {
        owner: instructor,
        program: program,
        school: school
      }
      course_1 = create(:open_course, default_attrs.merge(name: 'course001'))
      course_2 = create(
        :course,
        default_attrs.merge(
          name: 'course002',
          start_date: 2.months.ago,
          end_date: 1.month.ago,
          allow_past_end_date: true
        )
      )
      create(
        :course,
        default_attrs.merge(
          start_date: 2.months.ago, end_date: (1.month.ago - 1.day), allow_past_end_date: true
        )
      )
      create(:open_course, default_attrs.merge(school: create(:school)))
      create(:open_course, default_attrs.merge(program: create(:program)))

      expect(
        instructor.editable_courses_by_school_and_program(school, program)
      ).to eq([course_1, course_2])
    end
  end

  def create_other_instructor_section(name, target_course)
    create(
      :section,
      course: target_course || other_owner_course,
      instructor: other_instructor,
      name: name
    )
  end

  def create_assistant_section(target_course = nil)
    section = create_other_instructor_section('assistant', target_course)
    create(:section_assistant, instructor: instructor, section: section)
    section
  end

  def create_co_instructor_section(target_course = nil)
    section = create_other_instructor_section('co_instructor', target_course)
    create(:section_co_instructor, instructor: instructor, section: section)
    section
  end

  describe '#pubnub_client_roster' do
    def section_info(section)
      {
        id: "section_#{section.id}",
        name: section.name,
        users: [
          {
            first_name: section.instructor.first_name,
            last_name: section.instructor.last_name,
            uuid: section.instructor.id.to_s
          }
        ]
      }
    end

    let(:instructor) { create(:instructor) }
    let(:other_instructor) { create(:instructor) }
    let(:other_owner_course) { create(:open_course, owner: other_instructor) }

    it 'contains a :user key with a hash of basic user info' do
      expect(instructor.pubnub_client_roster[:user]).to eq(
        first_name: instructor.first_name,
        last_name: instructor.last_name,
        name: instructor.username,
        uuid: instructor.id.to_s
      )
    end

    it "contains a :roster key with a hash of the instructor's courses and sections" do
      course = create(:open_course, owner: instructor)
      section = create(:section, course: course, instructor: instructor)

      result = instructor.pubnub_client_roster[:roster][:groups]

      expect(result).to match_array [
        {
          chat_level: course.chat_level,
          id: "course_#{course.id}",
          name: course.name,
          program_id: course.program_id,
          sections: [
            {
              id: "section_#{section.id}",
              name: section.name,
              users: []
            }
          ]
        }
      ]
    end

    it 'includes sections with courses that end today' do
      today = Time.zone.now.to_date
      course = create(:course, end_date: today, owner: instructor)
      section = create(:section, course: course, instructor: instructor)

      result = instructor.pubnub_client_roster[:roster][:groups]

      expect(result).to match_array [
        {
          chat_level: course.chat_level,
          id: "course_#{course.id}",
          name: course.name,
          program_id: course.program_id,
          sections: [
            {
              id: "section_#{section.id}",
              name: section.name,
              users: []
            }
          ]
        }
      ]
    end

    it 'does not include sections for open demo courses' do
      course = create(:open_course, is_demo: true, owner: instructor)
      section = create(:section, course: course, instructor: instructor)

      result = instructor.pubnub_client_roster[:roster][:groups]

      expect(result).to be_empty
    end

    it 'does not include sections with courses that ended yesterday' do
      yesterday = Time.zone.now.to_date - 1
      closed_course = create(:closed_course, end_date: yesterday, owner: instructor)
      create(:section, course: closed_course, instructor: instructor)

      result = instructor.pubnub_client_roster[:roster][:groups]

      expect(result).to eq([])
    end

    it 'does not include sections for archived courses' do
      course = create(:course, is_archived: true, is_demo: false, owner: instructor)
      section = create(:section, course: course, instructor: instructor)

      result = instructor.pubnub_client_roster[:roster][:groups]

      expect(result).to be_empty
    end

    it 'does not include sections for archived demo courses' do
      course = create(:course, is_archived: true, is_demo: true, owner: instructor)
      section = create(:section, course: course, instructor: instructor)

      result = instructor.pubnub_client_roster[:roster][:groups]

      expect(result).to be_empty
    end

    it 'includes the courses and sections where the instructor is ' \
       'a co-Instructor or Assistant' do
      assistant_section = create_assistant_section
      co_instructor_section = create_co_instructor_section

      result = instructor.pubnub_client_roster[:roster][:groups]

      expect(result).to match_array [
        {
          chat_level: other_owner_course.chat_level,
          id: "course_#{other_owner_course.id}",
          name: other_owner_course.name,
          program_id: other_owner_course.program_id,
          sections: [
            section_info(assistant_section),
            section_info(co_instructor_section)
          ]
        }
      ]
    end

    it 'includes co-instructor sections with courses that end today' do
      today = Time.zone.now.to_date
      course = create(:course, end_date: today, owner: other_instructor)
      section = create(:section, course: course, instructor: other_instructor)

      create(
        :section_co_instructor, instructor: instructor, section: section
      )

      result = instructor.pubnub_client_roster[:roster][:groups]

      expect(result).to match_array [
        {
          chat_level: course.chat_level,
          id: "course_#{course.id}",
          name: course.name,
          program_id: course.program_id,
          sections: [section_info(section)]
        }
      ]
    end

    it 'does not include co-instructor sections with courses that ended yesterday' do
      yesterday = Time.zone.now.to_date - 1
      closed_course = create(:closed_course, end_date: yesterday, owner: other_instructor)
      section = create(:section, course: closed_course, instructor: other_instructor)

      create(
        :section_co_instructor, instructor: instructor, section: section
      )

      result = instructor.pubnub_client_roster[:roster][:groups]

      expect(result).to eq([])
    end

    context 'with student enrollments' do
      let(:course) { create(:open_course, owner: instructor) }
      let(:section) { create(:section, course:, instructor:) }
      let(:enrolled_student) { create_student_enrollment(section, 'enrolled') }
      let(:completed_student) { create_student_enrollment(section, 'marked_complete') }
      let(:users) do
        [enrolled_student, completed_student].map do |student|
          {
            uuid: student.id.to_s,
            first_name: student.first_name,
            last_name: student.last_name
          }
        end
      end
      let(:expected_roster) do
        [{
          chat_level: course.chat_level,
          id: "course_#{course.id}",
          name: course.name,
          program_id: course.program_id,
          sections: [{ id: "section_#{section.id}", name: section.name, users: }]
        }]
      end

      before do
        enrolled_student
        completed_student
        create_student_enrollment(section, 'dropped')
      end

      def create_student_enrollment(section, state = 'enrolled')
        student = create(:student)
        create(:enrollment, user: student, section:, state:)
        student
      end

      it 'includes enrolled and completed students while excluding dropped students' do
        expect(instructor.pubnub_client_roster[:roster][:groups]).to match_array(expected_roster)
      end
    end
  end

  describe '#pubnub_grants_roster' do
    let(:instructor) { create(:instructor) }
    let(:course) { create(:open_course, owner: instructor) }
    let(:other_instructor) { create(:instructor) }
    let(:other_owner_course) { create(:open_course, owner: other_instructor) }

    it 'includes sections the instructor owns' do
      section = create(:section, course: course, instructor: instructor, name: 'owned')

      result = instructor.pubnub_grants_roster[:roster][:groups]

      expect(result).to match_array [
        { id: "section_#{section.id}", name: section.name }
      ]
    end

    it 'includes sections where the instructor is co-Instructor or Assistant' do
      assistant_section = create_assistant_section
      co_instructor_section = create_co_instructor_section

      result = instructor.pubnub_grants_roster[:roster][:groups]

      expect(result).to match_array [
        { id: "section_#{assistant_section.id}", name: assistant_section.name },
        { id: "section_#{co_instructor_section.id}", name: co_instructor_section.name }
      ]
    end

    it 'does not include archived sections' do
      create(:section, archived: true, instructor: instructor)

      result = instructor.pubnub_grants_roster[:roster][:groups]

      expect(result).to eq([])
    end

    it 'includes sections with courses that end today' do
      today = Time.zone.now.to_date
      course_ending_today = create(:course, end_date: today, owner: instructor)
      section = create(:section, course: course_ending_today, instructor: instructor)

      result = instructor.pubnub_grants_roster[:roster][:groups]

      expect(result).to match_array [
        { id: "section_#{section.id}", name: section.name }
      ]
    end

    it 'does not include sections with courses that ended yesterday' do
      yesterday = Time.zone.now.to_date - 1
      closed_course = create(:closed_course, end_date: yesterday, owner: instructor)
      create(:section, course: closed_course, instructor: instructor)

      result = instructor.pubnub_grants_roster[:roster][:groups]

      expect(result).to eq([])
    end

    it 'does not include sections in courses with chat disabled' do
      chat_disabled_course = create(
        :open_course,
        chat_level: 'disabled',
        owner: instructor
      )
      create(:section, course: chat_disabled_course, instructor: instructor)

      other_owner_course = create(
        :open_course,
        chat_level: 'disabled',
        owner: other_instructor
      )
      create_assistant_section(other_owner_course)

      result = instructor.pubnub_grants_roster[:roster][:groups]

      expect(result).to eq([])
    end
  end

  describe "sections" do
    before(:each) do
      @instructor = create(:instructor)
      open_course = create(:open_course, :owner => @instructor, :school => @school, :program => @program)
      closed_course = create(:closed_course, :owner => @instructor, :school => @school, :program => @program)

      @open_section = create(:section, :course => open_course, :instructor => @instructor, :name => 'A')
      @closed_section = create(:section, :course => closed_course, :instructor => @instructor, :name => 'B')
    end

    describe ".open_sections" do
      it "returns sections in open courses that belong to the instructor" do
        expect(@instructor.open_sections).to eq([@open_section])
      end

      it 'does not return sections that belong to another instructor' do
        another_instructor = create(:instructor)
        another_open_course = create(:open_course, :owner => another_instructor, :school => @school, :program => @program)
        create(:section, :course => another_open_course, :instructor => another_instructor, :name => 'Another')
        expect(@instructor.open_sections).to eq([@open_section])
      end
    end

    describe '.closed_sections' do
      it 'returns sections in closed courses that belong to the instructor' do
        expect(@instructor.closed_sections).to eq([@closed_section])
      end
    end

    describe '#chat_sections' do
      it 'returns sections for courses that closes today' do
        course = create(:course,
                        owner: @instructor,
                        school: @school,
                        program: @program,
                        end_date: Time.zone.today)

        section = create(:section, course: course, instructor: @instructor, name: 'C')

        expect(@instructor.chat_sections).to eq([@open_section, section])
      end

      it 'does not return sections for courses that are archived' do
        course = create(:course,
                        owner: @instructor,
                        school: @school,
                        program: @program,
                        is_archived: true)

        create(:section, course: course, instructor: @instructor, name: 'C')

        expect(@instructor.chat_sections).to eq([@open_section])
      end

      it 'does not return sections for archived demo courses' do
        course = create(:course,
                        owner: @instructor,
                        school: @school,
                        program: @program,
                        is_demo: true,
                        is_archived: true)

        create(:section, course: course, instructor: @instructor, name: 'C')

        expect(@instructor.chat_sections).to eq([@open_section])
      end

      it 'does not return sections for demo courses that are not archived' do
        course = create(:course,
                        owner: @instructor,
                        school: @school,
                        program: @program,
                        is_demo: true,
                        is_archived: false)

        create(:section, course: course, instructor: @instructor, name: 'C')

        expect(@instructor.chat_sections).to eq([@open_section])
      end
    end

    describe '.sections_of_editable_courses_by_program' do
      it 'returns sections of open courses of the instructor' do
        expect(@instructor.sections_of_editable_courses_by_program(@program)).to eq([@open_section])
      end

      it 'returns sections of closed editable courses of the instructor' do
        @closed_section.course.update(end_date: 7.days.ago)
        expect(@instructor.sections_of_editable_courses_by_program(@program)).to match_array([@open_section, @closed_section])
      end

      it 'returns sections of open course where the instructor is co-instructor' do
        other_instructor = create(:instructor)
        create(:section_co_instructor, section: @open_section, instructor: other_instructor)
        expect(other_instructor.sections_of_editable_courses_by_program(@program)).to eq([@open_section])
      end

      it 'does not return sections of editable course of other programs' do
        other_program = build_stubbed(:program)
        other_program_course = create(:course, owner: @instructor, school: @school, program: other_program)
        other_program_section = create(:section, course: other_program_course, instructor: @instructor, name: 'other_program_section')
        expect(@instructor.sections_of_editable_courses_by_program(@program)).not_to include other_program_section
      end

      it 'does not return sections of course that are no longer editable' do
        expect(@instructor.sections_of_editable_courses_by_program(@program)).not_to include @closed_section
      end
    end
  end

  describe '#sections_by_program' do
    it 'returns all sections in unarchived courses that the instructor has access to at a given program' do
      instructor = create(:instructor)
      program = create(:program)
      course_1 = create(:course, :program => program)
      course_2 = create(:course) # different program
      course_3 = create(:course, :program => program, :is_archived => true)
      section_1 = create(:section, :course => course_1, :instructor => instructor)
      section_2 = create(:section, :instructor => instructor) # different course
      section_3 = create(:section, :course => course_2, :instructor => instructor)
      section_4 = create(:section, :course => course_3, :instructor => instructor)

      expect(instructor.sections_by_program(program)).to eq([section_1])
    end
  end

  describe '#editable_sections_by_program' do
    let(:instructor) { create(:instructor) }
    let(:program) { create(:program) }

    it 'returns all editable sections that the instructor has access to at a given program'do
      course_1 = create(:open_course, :program => program)
      course_2 = create(:closed_course, :program => program)
      section_1 = create(:section, :course => course_1, :instructor => instructor)
      section_2 = create(:section, :course => course_2, :instructor => instructor)

      expect(instructor.editable_sections_by_program(program)).to eq([section_1])
    end

    it 'excludes sections in archived courses' do
      unarchived_course = create(:open_course, :program => program, :is_archived => false)
      unarchived_course_section = create(:section, :course => unarchived_course, :instructor => instructor)

      archived_course = create(:course, :program => program, :is_archived => true)
      archived_course_section = create(:section, :course => archived_course, :instructor => instructor)

      expect(instructor.editable_sections_by_program(program)).to eq([unarchived_course_section])
    end

    it 'excludes templates' do
      non_template_course = create(:course, program: program)
      template_course = create(:course_template, program: program)

      [non_template_course, template_course].each do |course|
        create(:section, course: course, instructor: instructor)
        course.end_date = 6.months.from_now.to_date
        course.save!
      end

      expect(instructor.editable_sections_by_program(program)).to eq([non_template_course.sections.first])
    end
  end

  describe '#sections_by_school_and_program' do
    it 'returns all sections that the instructor has access to for a given school and program' do
      instructor = create(:instructor)
      school = create(:school)
      program = create(:program)
      course_1 = create(:course, :school => school, :program => program)
      course_2 = create(:course, :school => school) # different program
      course_3 = create(:course, :program => program) # different school
      section_1 = create(:section, :course => course_1, :instructor => instructor)
      section_2 = create(:section, :course => course_2, :instructor => instructor)
      section_3 = create(:section, :course => course_3, :instructor => instructor)

      expect(instructor.sections_by_school_and_program(school, program)).to eq([section_1])
    end
  end

  describe '#editable_sections_by_school_and_program' do
    let(:instructor) { create(:instructor) }
    let(:program) { create(:program) }
    let(:school) { create(:school) }

    it 'returns all sections in an editable course that the instructor has access to for a given school and program' do
      course_1 = create(:open_course, :school => school, :program => program)
      course_2 = create(:closed_course, :school => school, :program => program)
      course_3 = create(:course, :school => school) # different program
      course_4 = create(:course, :program => program) # different school
      section_1 = create(:section, :course => course_1, :instructor => instructor)
      section_2 = create(:section, :course => course_2, :instructor => instructor)
      section_3 = create(:section, :course => course_3, :instructor => instructor)
      section_4 = create(:section, :course => course_4, :instructor => instructor)

      expect(instructor.editable_sections_by_school_and_program(school, program)).to eq([section_1])
    end

    it 'excludes sections in archived courses' do
      unarchived_course = create(:open_course, :program => program, :school => school, :is_archived => false)
      unarchived_course_section = create(:section, :course => unarchived_course, :instructor => instructor)
      archived_course = create(:open_course, :program => program, :school => school, :is_archived => true)
      archived_course_section = create(:section, :course => archived_course, :instructor => instructor)

      expect(instructor.editable_sections_by_school_and_program(school, program)).to eq([unarchived_course_section])
    end
  end

  describe '#closed_sections_by_school_and_program' do
    let(:instructor) { create(:instructor) }
    let(:program) { create(:program) }
    let(:school) { create(:school) }

    it 'returns all sections in an open course that the instructor has access to for a given school and program' do
      course_1 = create(:open_course, :school => school, :program => program)
      course_2 = create(:closed_course, :school => school, :program => program)
      course_3 = create(:course, :school => school) # different program
      course_4 = create(:course, :program => program) # different school
      section_1 = create(:section, :course => course_1, :instructor => instructor)
      section_2 = create(:section, :course => course_2, :instructor => instructor)
      section_3 = create(:section, :course => course_3, :instructor => instructor)
      section_4 = create(:section, :course => course_4, :instructor => instructor)

      expect(instructor.closed_sections_by_school_and_program(school, program)).to eq([section_2])
    end

    it 'excludes sections in archived courses' do
      unarchived_course = create(:closed_course, :program => program, :school => school, :is_archived => false)
      unarchived_course_section = create(:section, :course => unarchived_course, :instructor => instructor)
      archived_course = create(:closed_course, :program => program, :school => school, :is_archived => true)
      archived_course_section = create(:section, :course => archived_course, :instructor => instructor)

      expect(instructor.closed_sections_by_school_and_program(school, program)).to eq([unarchived_course_section])
    end
  end

  describe '#editable_courses_without_sections_by_program' do
    let!(:instructor) { create(:instructor) }
    let!(:program) { create(:program) }
    let!(:course_1) { create(:open_course, :program => program, :owner => instructor) }
    let!(:course_2) { create(:open_course, :program => program, :owner => instructor) }
    let!(:section_1) { create(:section, :course => course_1, :instructor => instructor) }

    it 'returns all editable courses without sections for a given program' do
      expect(instructor.editable_courses_without_sections_by_program(program)).to eq([course_2])
    end

    it "returns editable courses with only archived sections" do
      section_1 = create(:section, :course => course_2, :instructor => instructor, :is_archived => 1)
      expect(instructor.editable_courses_without_sections_by_program(program)).to eq([course_2])
    end

    it 'excludes templates' do
      create(:course_template, end_date: 6.months.from_now.to_date, owner: instructor)
      expect(instructor.editable_courses_without_sections_by_program(program)).to eq([course_2])
    end
  end

  describe '#editable_courses_without_sections_by_school_and_program' do
    let!(:instructor) { create(:instructor) }
    let!(:school) { create(:school) }
    let!(:program) { create(:program) }
    let!(:course_1) { create(:open_course, :school => school, :program => program, :owner => instructor) }
    let!(:course_2) { create(:open_course, :school => school, :program => program, :owner => instructor) }
    let!(:course_3) { create(:open_course,
                             school: school,
                             program: program,
                             owner: instructor,
                             hide_from_instructor_dashboard: true) }
    let!(:section_1) { create(:section, :course => course_1, :instructor => instructor) }

    it 'returns all editable courses without sections for a given school and program' do
      expect(instructor.editable_courses_without_sections_by_school_and_program(school, program)).to eq([course_2])
    end

    it "returns editable courses with only archived sections" do
      section_1 = create(:section, :course => course_2, :instructor => instructor, :is_archived => 1)
      expect(instructor.editable_courses_without_sections_by_school_and_program(school, program)).to eq([course_2])
    end
  end

  describe "#open_courses_for_program" do
    before(:each) do
      @instructor = create(:instructor)
      @program = create(:program)
    end

    it "should not return closed courses" do
      valid_course   = create(:course, :owner => @instructor, :school => @school, :program => @program, :end_date => 5.days.from_now)
      invalid_course = create(:closed_course, :owner => @instructor, :school => @school, :program => @program, :end_date => 1.day.ago)
      expect(@instructor.open_courses_for_program(@program)).to eq([valid_course])
    end

    it "should return only courses in the current program" do
      valid_course   = create(:course, :owner => @instructor, :school => @school, :program => @program)
      invalid_course = create(:course, :owner => @instructor, :school => @school, :program => create(:program))
      expect(@instructor.open_courses_for_program(@program)).to eq([valid_course])
    end
  end

  describe "#closed_courses_for_program" do
    before(:each) do
      @instructor = create(:instructor)
      @program_1 = create(:program)
      @program_2 = create(:program)
    end

    it "should return closed cources" do
      @active_course = create(:course, :owner => @instructor, :school => @school, :program => @program)

      @closed_course_1 = create(:closed_course, :owner => @instructor, :school => @school, :program => @program_1, :start_date => 100.days.ago, :end_date => 1.day.ago)
      @closed_course_2 = create(:closed_course, :owner => @instructor, :school => @school, :program => @program_2, :start_date => 100.days.ago, :end_date => 1.day.ago)

      expect(@instructor.closed_courses_for_program(@program_1)).to eq([@closed_course_1])
    end
  end

  describe '.editable_courses_for_program' do
    before do
      @instructor = create(:instructor)
      @program_1 = create(:program)
      @program_2 = create(:program)
    end

    it "returns editable courses" do
      @active_course = create(:course, :owner => @instructor, :school => @school, :program => @program_1)

      @editable_course = create(:closed_course, :owner => @instructor, :school => @school, :program => @program_1, :start_date => 100.days.ago, :end_date => 1.day.ago)

      @closed_course = create(:closed_course, :owner => @instructor, :school => @school, :program => @program_1, :start_date => 100.days.ago, :end_date => 2.months.ago)

      @editable_course_other_program = create(:closed_course, :owner => @instructor, :school => @school, :program => @program_2, :start_date => 100.days.ago, :end_date => 1.day.ago)

      expect(@instructor.editable_courses_for_program(@program_1)).to include(@active_course)
      expect(@instructor.editable_courses_for_program(@program_1)).to include(@editable_course)
    end
  end

  describe '#courses_and_sections_for_focus' do
    let(:instructor) { create(:instructor) }
    let(:program) { create(:program) }

    it 'returns all courses and sections that the instructor has access to' do
      owned_course = create(:course, :program => program, :owner => instructor)
      course_different_owner = create(:course, :program => program)
      course_no_sections = create(:course, :program => program, :owner => instructor)
      owned_section = create(:section, :course => owned_course, :instructor => instructor)
      teaching_section = create(:section, :course => course_different_owner, :instructor => instructor)
      excluded_section = create(:section, :course => course_different_owner) # not a teacher, so no access

      expected = { owned_course => [owned_section], course_different_owner => [teaching_section], course_no_sections => [] }
      expect(instructor.courses_and_sections_for_focus(program)).to eq(expected)
    end

    it 'returns the courses in the order specified by the user setting' do
      course_1 = create(:course, :program => program, :owner => instructor)
      course_2 = create(:course, :program => program, :owner => instructor)
      course_3 = create(:course, :program => program, :owner => instructor)
      allow(instructor).to receive(:setting).with("course_order_#{program.id}".to_sym)
                               .and_return("#{course_1.id},#{course_3.id},#{course_2.id}")
      expected = { course_1 => [], course_3 => [], course_2 => [] }
      expect(instructor.courses_and_sections_for_focus(program)).to eq(expected)
    end

    it 'returns the courses that are not hidden from the instructor dashboard' do
      course_shown = create(:course, program: program, owner: instructor)
      course_hidden = create(:course, program: program, owner: instructor)
      section_shown = create(:section, course: course_shown, instructor: instructor)
      section_hidden = create(:section, course: course_hidden, instructor: instructor)
      course_hidden.hide_from_instructor_dash(true)

      expected = { course_shown => [section_shown] }
      expect(instructor.courses_and_sections_for_focus(program)).to eq(expected)
    end

    context 'with enterprise created courses' do
      let(:enterprise_course) do
        create(:enterprise_course, owner: instructor, program:)
      end
      let(:section) { create(:section, course: enterprise_course, instructor:) }
      let(:co_instructor) { create(:instructor) }
      let!(:co_instructor_section_instructor) do
        create(:section_co_instructor, instructor: co_instructor, section:)
      end
      let(:expected_course_section) do
        { enterprise_course => [section] }
      end

      before do
        section.reload
      end

      it 'returns the courses to be displayed for the course owner and co-instructor, ' \
         'if there default display settings are present' do
        instructor_results = instructor.courses_and_sections_for_focus(program)
        co_instructor_results = co_instructor.courses_and_sections_for_focus(program)
        expect(instructor_results).to eq expected_course_section
        expect(co_instructor_results).to eq expected_course_section
      end

      it 'returns the courses for the co-instructor, but not the owner, ' \
         'if the owner has set it to hide it from his dashboard' do
        enterprise_course.update(hide_from_instructor_dashboard: true)
        instructor_results = instructor.courses_and_sections_for_focus(program)
        co_instructor_results = co_instructor.courses_and_sections_for_focus(program)
        expect(instructor_results).to eq({})
        expect(co_instructor_results).to eq expected_course_section
      end

      it 'returns the courses for the course owner, but not the co-instructor, ' \
         'if the co-instructor has set it to hide it from his dashboard' do
        co_instructor_section_instructor.update(hide_from_instructor_dashboard: true)
        instructor_results = instructor.courses_and_sections_for_focus(program)
        co_instructor_results = co_instructor.courses_and_sections_for_focus(program)
        expect(instructor_results).to eq expected_course_section
        expect(co_instructor_results).to eq({})
      end
    end
  end

  describe '#courses_and_sections_for_dashboard' do
    let(:school) { create(:school) }
    let(:program) { create(:program) }

    context 'when the instructor has access to courses and sections' do
      let(:instructor) { create(:instructor) }
      let(:institution_admin) { create(:institution_admin) }

      it 'returns all courses and sections, including enterprise courses if the instructor is not the owner' do
        owned_course = create(:course, program: program, school: school, owner: instructor)
        enterprise_course = create(:enterprise_course, program: program, school: school, owner: institution_admin)
        enterprise_course_section = create(:section, course: enterprise_course, instructor: instructor)
        owned_section = create(:section, course: owned_course, instructor: instructor)

        expected = {
          owned_course => [owned_section],
          enterprise_course => [enterprise_course_section]
        }
        expect(instructor.courses_and_sections_for_dashboard(school, program)).to eq(expected)
      end

      it 'does not show enterprise courses if the instructor is the owner and hide_from_instructor_dashboard is true' do
        hidden_course = create(:enterprise_course, program: program, school: school, owner: institution_admin, hide_from_instructor_dashboard: true)
        expect(institution_admin.courses_and_sections_for_dashboard(school, program)).to eq({})
      end

      it 'shows enterprise courses if the instructor is the owner and hide_from_instructor_dashboard is false' do
        visible_course = create(:enterprise_course, program: program, school: school, owner: institution_admin, hide_from_instructor_dashboard: false)

        expected = { visible_course => [] }
        expect(institution_admin.courses_and_sections_for_dashboard(school, program)).to eq(expected)
      end
    end

    context 'when course order is specified by user settings' do
      let(:instructor) { create(:instructor) }

      it 'returns the courses in the specified order' do
        course_1 = create(:course, program: program, owner: instructor, school: school)
        course_2 = create(:course, program: program, owner: instructor, school: school)
        course_3 = create(:course, program: program, owner: instructor, school: school)
        allow(instructor).to receive(:setting).with("course_order_#{program.id}".to_sym)
                                  .and_return("#{course_1.id},#{course_3.id},#{course_2.id}")

        expected = { course_1 => [], course_3 => [], course_2 => [] }
        expect(instructor.courses_and_sections_for_dashboard(school, program)).to eq(expected)
      end
    end

    context 'when visibility settings apply' do
      let(:instructor) { create(:instructor) }

      it 'returns courses that are not hidden from the dashboard' do
        visible_course = create(:course, program: program, school: school, owner: instructor)
        hidden_course = create(:course, program: program, school: school, owner: instructor, hide_from_instructor_dashboard: true)
        section_shown = create(:section, course: visible_course, instructor: instructor)

        expected = { visible_course => [section_shown] }
        expect(instructor.courses_and_sections_for_dashboard(school, program)).to eq(expected)
      end
    end

    context 'when no courses or templates are present' do
      let(:instructor) { create(:instructor) }

      it 'returns an empty hash when there are no courses' do
        expect(instructor.courses_and_sections_for_dashboard(school, program)).to eq({})
      end

      it 'does not include course templates' do
        create(:course, is_template: true, owner: instructor, program: program, school: school)
        template_course = create(:course, is_template: true, owner: instructor, program: program, school: school)
        create(:section, course: template_course, instructor: instructor)

        expect(instructor.courses_and_sections_for_dashboard(school, program)).to eq({})
      end
    end
  end

  describe "#courses_for_program" do
    before(:each) do
      @instructor = create(:instructor)
      @program = create(:program)
      @closed_course = create(:closed_course, :owner => @instructor, :school => @school, :program => @program, :end_date => 1.day.ago)
      @open_course   = create(:course, :owner => @instructor, :school => @school, :program => @program, :end_date => 5.days.from_now)
    end

    it "should return both open and closed courses, with open courses first" do
      expect(@instructor.courses_for_program(@program)).to eq([@open_course, @closed_course])
    end

    it "should exclude courses from other programs" do
      invalid_course = create(:course, :owner => @instructor, :school => @school, :program => create(:program))
      expect(@instructor.courses_for_program(@program)).not_to include invalid_course
    end
  end

  describe "#open_courses_by_school_for_program" do
    before(:each) do
      @instructor = create(:instructor)
      @program_1 = create(:program)
      @program_2 = create(:program)
      @school_1 = create(:school)
      @school_2 = create(:school)
    end

    it "should return open cources by school" do
      @school_1_course_1 = create(:course, :owner => @instructor, :school => @school_1, :program => @program_1)
      @school_1_course_2 = create(:course, :owner => @instructor, :school => @school_1, :program => @program_2)

      @school_2_course = create(:course, :owner => @instructor, :school => @school_2, :program => @program_2)
      desired_result = {@school_1 => [@school_1_course_1]}
      expect(@instructor.open_courses_by_school_for_program(@program_1)).to eq(desired_result)
    end
  end

  describe "#closed_courses_by_school_for_program" do
    before(:each) do
      @instructor = create(:instructor)
      @program_1 = create(:program)
      @program_2 = create(:program)
      @school_1 = create(:school)
      @school_2 = create(:school)
    end

    it "should return only closed cources by school" do
      @school_1_course_1 = create(:course, :owner => @instructor,
                                   :school => @school_1, :program => @program_1)
      @school_1_course_2 = create(:course, :owner => @instructor,
                                   :school => @school_1, :program => @program_1)
      @school_1_course_3 = create(:closed_course, :owner => @instructor,
                                   :start_date => 6.months.ago, :end_date => 10.days.ago,
                                   :school => @school_1, :program => @program_1)

      @school_2_course_1 = create(:course, :owner => @instructor,
                                   :school => @school_2, :program => @program_1)
      @school_2_course_2 = create(:closed_course, :owner => @instructor,
                                   :start_date => 6.months.ago, :end_date => 10.days.ago,
                                   :school => @school_2, :program => @program_1)
      desired_result = {@school_1 => [@school_1_course_3],
                        @school_2 => [@school_2_course_2]}

      expect(@instructor.closed_courses_by_school_for_program(@program_1)).to eq(desired_result)
    end
  end

  describe "#courses_by_school_for_program" do
    before(:each) do
      @instructor = create(:instructor)
      @program_1 = create(:program)
      @program_2 = create(:program)
      @school_1 = create(:school)
      @school_2 = create(:school)
    end

    it 'should return both closed and open courses by school' do
      @school_1_course_1 = create(:course, owner: @instructor,
                                            school: @school_1,
                                            program: @program_1)
      @school_1_course_2 = create(:course, owner: @instructor,
                                            school: @school_1,
                                            program: @program_1)
      @school_1_course_3 = create(:closed_course, owner: @instructor,
                                                   start_date: 6.months.ago,
                                                   end_date: 10.days.ago,
                                                   school: @school_1,
                                                   program: @program_1)

      @school_2_course_1 = create(:course, owner: @instructor,
                                            school: @school_2,
                                            program: @program_2)
      @school_2_course_2 = create(:closed_course, owner: @instructor,
                                                   start_date: 6.months.ago,
                                                   end_date: 10.days.ago,
                                                   school: @school_2,
                                                   program: @program_2)

      result = @instructor.courses_by_school_for_program(@program_1)
      expect(result.size).to eq(1)
      expect(result[@school_1]).to match_array([@school_1_course_1,
                                                @school_1_course_2,
                                                @school_1_course_3])
    end
  end

  describe "#most_recent_school_id" do
    context "has courses" do
      before(:each) do
        @instructor = create(:instructor)
        @program = create(:program)
        @school_1 = create(:school)
        @school_2 = create(:school)
      end

      it "should return the schoold id of the last updated course" do
        @course_1 = create(:course,
                            :owner => @instructor,
                            :school => @school_1,
                            :program => @program,
                            :start_date => 100.days.ago,
                            :end_date => 100.days.from_now,
                            :updated_at => 2.days.ago,
                            :created_at => 100.days.ago)
        @course_2 = create(:course,
                            :owner => @instructor,
                            :school => @school_2,
                            :program => @program,
                            :start_date => 100.days.ago,
                            :end_date => 100.days.from_now,
                            :updated_at => 1.days.ago,
                            :created_at => 100.days.ago)

        expect(@instructor.most_recent_school_id).to eq(@school_2.id)
      end
    end

    context "has no courses" do
      before(:each) do
        @instructor = create(:instructor)
        @program_1 = create(:program)
        @school_1 = create(:school)
        @school_2 = create(:school)
        #create(:school_user, :user_id => @instructor.id, :school_id => @school_1)
        create(:school_user, :user_id => @instructor.id, :school_id => @school_2.id)
      end

      it "should return last updated school" do
        expect(@instructor.most_recent_school_id).to eq(@school_2.id)
      end
    end
  end

  describe "#fellow_instructor_ids" do
    let(:school) { create(:school) }
    let(:instructor) { create(:instructor, :schools => [school]) }
    let!(:colleague_instructor_1) { create(:instructor, :schools => [school]) }
    let!(:instructor_2) { create(:instructor, :schools => [create(:school)]) }

    it "returns a list of the user_ids of the instructors that are in his same schools" do
      instructor_ids = instructor.fellow_instructor_ids
      expect(instructor_ids).to include colleague_instructor_1.id
      expect(instructor_ids).not_to include instructor_2.id
      expect(instructor_ids).not_to include instructor.id
    end

    it "doesn't return ids for archived users" do
      archived_user = create(:instructor, schools: [school], archived: true)
      instructor_ids = instructor.fellow_instructor_ids
      expect(instructor_ids).to include colleague_instructor_1.id
      expect(instructor_ids).not_to include archived_user.id
    end
  end

  describe "#all_sections_for_program" do
    before(:each) do
      @instructor = create(:instructor)
      other_program = create(:program)
      course_in_program = create(:course, :name => 'right course', :owner => @instructor, :program => @program)
      course_in_other_program = create(:course, :name => 'wrong course', :owner => @instructor, :program => other_program)
      course_in_program_other_instructor = create(:course, :name => 'wrong course 2', :owner => create(:instructor), :program => @program)
      @section = create(:section, :name => 'right section', :course => course_in_program, :instructor => @instructor)
      other_sections = [
        create(:section, :name => 'wrong section', :course => course_in_other_program),
        create(:section, :name => 'wrong section 2', :course => course_in_program_other_instructor)]
    end

    it "should return all of the instructor's sections for the specified program" do
      expect(@instructor.all_sections_for_program(@program)).to eq([@section])
    end
  end

  describe "#sections_grouped_by_school_id" do
    let(:school) { create(:school) }
    let(:instructor) { create(:instructor, :schools => [school]) }
    let(:course) { create(:course, :school => school) }
    let(:section) { create(:section, :course => course) }

    it "returns a hash that maps school ids to arrays of editable sections for that school" do
      expect(instructor).to receive(:editable_sections_by_school_and_program).and_return([section])
      expect(instructor.sections_grouped_by_school_id(course.program)).to eq({ school.id => [section] })
    end
  end

  describe "#downloadable_resource" do
    let(:program) { create(:program) }
    let(:program_resource) { create(:resource, :program => program) }
    let(:instructor) { create(:instructor) }

    it "returns the resource with the specified id if it belongs to the specified program" do
      resource = instructor.downloadable_resource(program_resource.id, program)
      expect(resource).to eq(program_resource)
    end

    it "raises a record not found error if it tries to retrieve a resource that does not belong to the specified program" do
      other_program = create(:program)
      other_program_resource = create(:resource, :program => other_program)
      expect{ instructor.downloadable_resource(other_program_resource.id, program) }.to raise_error ActiveRecord::RecordNotFound
    end

    it "raises a record not found error if it tries to retrieve a resource that has been uploaded by another instructor" do
      other_instructor = create(:instructor)
      other_instructor_resource =  create(:uploaded_resource, :owner => other_instructor, :program => program)
      expect{ instructor.downloadable_resource(other_instructor_resource.id, program) }.to raise_error ActiveRecord::RecordNotFound
    end

    it "returns the resource if has been uploaded by the instructor" do
      instructor_uploaded_resource = create(:uploaded_resource, :owner => instructor, :program => program)
      result = instructor.downloadable_resource(instructor_uploaded_resource.id, program)
      expect(result).to eq(instructor_uploaded_resource)
    end
  end

  describe "#demo_course_current?" do
    let(:program) { create(:program) }
    let(:instructor) { create(:instructor) }

    context "demo course with an up to date section" do
      let(:course) { create(:course_with_section, :is_demo => true, :owner => instructor, :program => program) }

      before do
        course.sections.first.update!(current_upto: Time.now)
      end

      it "returns true" do
        expect(instructor.demo_course_current?(program)).to be_truthy
      end
    end

    context "demo course with a non up to date section" do
      let(:course) { create(:course_with_section, :is_demo => true, :owner => instructor, :program => program) }

      it "returns false" do
        expect(instructor.demo_course_current?(program)).to be_falsey
      end
    end

    context "with no demo course" do
      it "returns false" do
        expect(instructor.demo_course_current?(program)).to be_falsey
      end
    end
  end

  describe 'after_save' do
    let(:instructor) { create(:instructor) }
    let(:section) { create(:section) }

    context 'when instructor is being archived' do
      it 'archives the related SectionInstructor records' do
        section_instructor = create(:section_instructor, :section => section, :instructor => instructor)
        expect(section_instructor).not_to be_is_archived
        instructor.archived = true
        instructor.save
        section_instructor.reload
        expect(section_instructor).to be_is_archived
      end
    end

    context 'when instructor is not being archived' do
      it 'does not archive the related SectionInstructor records' do
        section_instructor = create(:section_instructor, :section => section, :instructor => instructor)
        expect(section_instructor).not_to be_is_archived
        instructor.first_name = 'name changed'
        instructor.save
        section_instructor.reload
        expect(section_instructor).not_to be_is_archived
      end
    end
  end

  describe 'after_destroy' do
    let(:instructor) { create(:instructor) }
    let(:section) { create(:section) }

    it 'archives the related SectionInstructor records' do
      section_instructor = create(:section_instructor, :section => section, :instructor => instructor)
      expect(section_instructor).not_to be_is_archived
      instructor.destroy
      section_instructor.reload
      expect(section_instructor).to be_is_archived
    end
  end

  describe 'igc copy' do
    let(:destination_program) { create(:program_with_toc_entries) }
    let(:previous_destination_program) { create(:program_with_toc_entries) }
    let(:destination_program_lesson) { destination_program.lessons.first }
    let(:destination_program_strand) { destination_program_lesson.toc_entries.first }
    let(:source_program) { create(:program_with_toc_entries) }
    let(:source_program_lesson) { source_program.lessons.first }
    let(:source_program_strand) { source_program_lesson.toc_entries.first }
    let(:unmapped_source_program_strand) { source_program_lesson.toc_entries[1] }
    let(:instructor) { create(:instructor) }

    let(:activity_for_destination_program) do
      InstructorCreatedActivity.new(
        concept_id: destination_program_strand.location,
        instructor_id: instructor.id,
        lesson: destination_program_lesson,
        title: 'foo',
        toc_entry_id: destination_program_strand.location
      )
    end

    let(:activity_for_source_program) do
      InstructorCreatedActivity.new(
        concept_id: source_program_strand.location,
        instructor_id: instructor.id,
        lesson: source_program_lesson,
        title: 'foo',
        toc_entry_id: source_program_strand.location
      )
    end

    let(:unmapped_activity_for_source_program) do
      InstructorCreatedActivity.new(
        concept_id: unmapped_source_program_strand.location,
        instructor_id: instructor.id,
        lesson: source_program_lesson,
        title: 'foo',
        toc_entry_id: unmapped_source_program_strand.location
      )
    end

    let(:mapping) do
      build(
        :program_to_program_mapping,
        dest_program_id: destination_program.id,
        src_strand_id: source_program_strand.location,
        dest_strand_id: destination_program_strand.location
      )
    end

    before do
      create(
        :concept,
        id: destination_program_strand.location,
        lesson: destination_program_lesson,
        program: destination_program
      )

      create(
        :concept,
        id: source_program_strand.location,
        lesson: source_program_lesson,
        program: source_program
      )

      create(
        :concept,
        id: unmapped_source_program_strand.location,
        lesson: source_program_lesson,
        program: source_program
      )

      mapping.save!

      allow_any_instance_of(InstructorCreatedActivity).to receive(:generate_xml)
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_icon)
      allow_any_instance_of(InstructorCreatedActivity).to receive(:set_license_group_id)
    end

    let(:job) do
      create(
        :igc_copy_job,
        dest_program: destination_program,
        instructor: instructor,
        src_program: source_program
      )
    end

    let(:previous_job) do
      create(
        :igc_copy_job,
        dest_program: previous_destination_program,
        instructor: instructor,
        src_program: source_program
      )
    end

    describe '#igc' do
      it 'returns IGC in the given program for the instructor' do
        activity_for_source_program.save!

        expect(instructor.igc(source_program).pluck(:id)).to eq(
          [activity_for_source_program.id]
        )
      end

      it 'ignores IGC in unmapped strands' do
        activity_for_source_program.save!
        unmapped_activity_for_source_program.save!

        expect(instructor.igc(source_program).pluck(:id)).to eq(
          [activity_for_source_program.id]
        )
      end

      it 'returns no results if instructor has IGC, but not in the given program' do
        activity_for_source_program.save!

        expect(instructor.igc(destination_program)).not_to be_present
      end

      it 'returns no results if instructor has no IGC at all' do
        expect(instructor.igc(source_program)).not_to be_present
      end
    end

    describe '#has_igc?' do
      it 'returns true if instructor has IGC in the given program' do
        activity_for_source_program.save!

        expect(instructor.has_igc?(source_program)).to be true
      end

      it 'returns false if instructor has IGC, but not in the given program' do
        activity_for_source_program.save!

        expect(instructor.has_igc?(destination_program)).to be false
      end

      it 'returns false if instructor has no IGC at all' do
        expect(instructor.has_igc?(source_program)).to be false
      end
    end

    describe '#has_uncopied_igc_for_source_program?' do
      context 'when a program is mapped to the given program' do
        context 'when the user has IGC for the source program' do
          before do
            # create an activity in the source program
            activity_for_source_program.save!
          end

          it 'returns true if the IGC copy has not been run' do
            expect(instructor.has_uncopied_igc_for_source_program?(destination_program)).to be true
          end

          it 'returns true if the IGC copy is not complete' do
            create(:igc_copy_job,
                   src_program: source_program,
                   dest_program: destination_program,
                   instructor: instructor,
                   to_be_copied_ids: [activity_for_source_program.id],
                   copied_ids: [])

            expect(instructor.has_uncopied_igc_for_source_program?(destination_program)).to be true
          end

          it 'returns false if the IGC is all copied' do
            create(:igc_copy_job,
                   src_program: source_program,
                   dest_program: destination_program,
                   instructor: instructor,
                   to_be_copied_ids: [],
                   copied_ids: [activity_for_source_program.id])

            expect(instructor.has_uncopied_igc_for_source_program?(destination_program)).to be false
          end
        end

        it 'returns false if instructor does not have IGC for the source program' do
          expect(instructor.has_uncopied_igc_for_source_program?(destination_program)).to be false
        end
      end

      it 'returns false if no program is a source for the given program' do
        expect(instructor.has_uncopied_igc_for_source_program?(destination_program)).to be false
      end
    end

    describe '#has_copied_all_igc?' do
      it 'raises an error if no IGC exists' do
        # The predicate has no valid meaning if there is no IGC.
        #   It should be called only after checking that IGC exists.
        expect { instructor.has_copied_all_igc?(source_program, destination_program) }
          .to raise_error('This method is invalid if the instructor has no IGC.')
      end

      context 'when IGC exists' do
        before do
          activity_for_source_program.save!
        end

        it 'returns true if a copy job exists for the IGC and all existing IGC is in its list of copied IGC' do
          job.copied_ids = [activity_for_source_program.id]
          job.save!

          expect(instructor.has_copied_all_igc?(source_program, destination_program)).to be true
        end

        it 'returns false if a copy job exists for the IGC and not all existing IGC is in its list of copied IGC' do
          job.copied_ids = []
          job.save!

          expect(instructor.has_copied_all_igc?(source_program, destination_program)).to be false
        end

        it 'returns false if IGC exists and no copy job exists for it' do
          expect(instructor.has_copied_all_igc?(source_program, destination_program)).to be false
        end
      end
    end

    describe '#igc_ids_to_copy' do
      let(:results) { double() }

      it 'returns an empty array if the instructor has no IGC' do
        allow(results).to receive(:pluck).and_return([])
        allow(instructor).to receive(:igc).and_return(results)

        expect(instructor.igc_ids_to_copy(source_program, destination_program)).to eq([])
      end

      context 'when a copy job has already run' do
        it 'returns an empty array if all IGC is copied' do
          allow(results).to receive(:pluck).and_return([1, 2, 3])
          allow(instructor).to receive(:igc).and_return(results)
          job.copied_ids = [1, 2, 3]
          job.save!

          expect(instructor.igc_ids_to_copy(source_program, destination_program)).to eq([])
        end

        it 'returns an array of all IGC ids if no IGC has been copied' do
          allow(results).to receive(:pluck).and_return([1, 2, 3])
          allow(instructor).to receive(:igc).and_return(results)
          job.copied_ids = []
          job.save!

          expect(instructor.igc_ids_to_copy(source_program, destination_program)).to eq([1, 2, 3])
        end

        it 'returns an array of uncopied IGC ids if some IGC has been copied' do
          allow(results).to receive(:pluck).and_return([1, 2, 3])
          allow(instructor).to receive(:igc).and_return(results)
          job.copied_ids = [2]
          job.save!

          expect(instructor.igc_ids_to_copy(source_program, destination_program)).to eq([1, 3])
        end
      end

      context 'when the source program is mapped to a new destination' do
        it 'returns an array of uncopied IGC ids for the new source and desination program' do
          allow(results).to receive(:pluck).and_return([1, 2, 3])
          allow(instructor).to receive(:igc).and_return(results)
          previous_job.copied_ids = [1]
          previous_job.save!

          job.copied_ids = []
          job.save!

          expect(instructor.igc_ids_to_copy(source_program, previous_destination_program)).to eq([2, 3])
          expect(instructor.igc_ids_to_copy(source_program, destination_program)).to eq([1, 2, 3])
        end
      end
    end

    describe '#uncopied_igc_count' do
      let(:results) { double() }

      it 'returns the count of uncopied IGC' do
        allow(results).to receive(:pluck).and_return([1, 2, 3])
        allow(instructor).to receive(:igc).and_return(results)

        expect(instructor.uncopied_igc_count(source_program, destination_program)).to eq(3)
      end
    end
  end
end

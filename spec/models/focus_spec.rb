describe Focus, core: true do
  let!(:student_sorter) { double(StudentSorter).as_null_object }
  let(:valid_user) { create(:instructor) }
  let(:valid_program) do
    create(:program, title: 'M3 Program', language_code: 'es', maestro_version: 3)
  end
  let(:valid_program_id) { valid_program.id.to_s }
  let(:valid_focus_params) { {} }

  alias_method :create_valid_program, :valid_program
  alias_method :create_valid_user, :valid_user

  before do
    create_valid_program
    create_valid_user
    allow(StudentSorter).to receive(:new).and_return(student_sorter)
  end

  it 'creates a new instance given valid attributes' do
    expect(Focus.new(valid_user, valid_program, valid_focus_params)).to be_truthy
  end

  describe '#section_name' do
    context 'when focused on a course' do
      it 'returns nil' do
        course = create(:course)
        focus = Focus.new(
          valid_user,
          valid_program,
          valid_program_id => { 'course_id' => course.id }
        )
        expect(focus.section_name).to be_nil
      end
    end

    context 'when focused on a section' do
      it 'returns the name of the focused section' do
        course = create(:course)
        section = create(:section)
        allow(Section).to receive(:find_by_id).with(section.id).and_return(section)
        focus = Focus.new(
          valid_user,
          valid_program,
          valid_program_id => {
            'course_id' => course.id,
            'section_id' => section.id
          }
        )
        expect(focus.section_name).to eq(section.name)
      end
    end
  end

  describe '#section_names' do
    context 'when focused on a course' do
      it 'returns a list of section names' do
        course = create(:course)
        section_1 = create(:section, course: course, instructor: valid_user)
        section_2 = create(:section, course: course, instructor: valid_user)
        focus = Focus.new(
          valid_user,
          valid_program,
          valid_program_id => {
            'course_id' => course.id
          }
        )
        expect(focus.section_names).to eq([section_1.name, section_2.name])
      end
    end

    context 'when focused on a section' do
      context 'and it is the only section in the course' do
        it "returns a list containing only that section's name" do
          course = create(:course)
          section = create(:section, course: course)
          focus = Focus.new(
            valid_user,
            valid_program,
            valid_program_id => {
              'course_id' => course.id,
              'section_id' => section.id
            }
          )
          expect(focus.section_names).to eq([section.name])
        end
      end

      context 'and it is not the only section in the course' do
        it "returns a list containing only that section's name" do
          course = create(:course)
          section = create(:section, course: course)
          other_section = create(:section, course: course)
          focus = Focus.new(
            valid_user,
            valid_program,
            valid_program_id => {
              'course_id' => course.id,
              'section_id' => section.id
            }
          )
          expect(focus.section_names).to eq([section.name])
        end
      end
    end
  end

  describe '#css_type_and_id' do
    it 'returns the type and id formatted for css' do
      course = create(:course)
      section = create(:section)
      focus = Focus.new(
        valid_user, valid_program,
        valid_program_id => {
          'course_id' => course.id,
          'section_id' => section.id
        }
      )
      expect(focus.css_type_and_id).to eq("section_#{section.id}")
    end
  end

  describe '#course_school_id' do
    let(:school) { create(:school) }
    let(:course) { create(:course, program: valid_program, school_id: school.id) }

    it 'returns the school for the course' do
      allow(Course).to receive(:find).and_return(course)
      focus = described_class.new(
        valid_user,
        valid_program,
        valid_program_id => {
          'course_id' => course.id,
          'section_id' => nil
        }
      )
      expect(focus.course_school_id).to eq(school.id)
    end

    it 'returns nil when there is no course' do
      focus = described_class.new(
        valid_user,
        valid_program,
        valid_program_id => {
          'course_id' => nil,
          'section_id' => nil
        }
      )
      expect(focus.course_school_id).to be_nil
    end
  end

  describe '#course' do
    before do
      @course = create(:course, program: valid_program)
      @section = create(:section, course: @course)
    end

    context 'with a course in focus' do
      it 'returns the course' do
        focus = Focus.new(
          valid_user,
          valid_program,
          valid_program_id => {
            'course_id' => @course.id,
            'section_id' => nil
          }
        )
        expect(focus.course).to eq(@course)
      end
    end

    context 'with a section in focus' do
      it "returns the section's course" do
        focus = Focus.new(
          valid_user, valid_program,
          valid_program_id => {
            'course_id' => nil,
            'section_id' => @section.id
          }
        )
        expect(focus.course).to eq(@course)
      end
    end

    context 'with an invalid course in focus,' do
      # Create a stubbed object to guarantee that we get a course id
      # that's not in use by a real course. Using a hardcoded number for
      # the id can make this test fail if @course from the before block
      # is created with the supposedly "invalid" id.
      let(:invalid_course_id) { build_stubbed(:course).id }
      let(:course) { build_stubbed(:course) }
      let(:focus) do
        Focus.new(
          valid_user,
          valid_program,
          valid_program_id => {
            'course_id' => invalid_course_id,
            'section_id' => nil
          }
        )
      end

      before do
        allow(focus).to receive(:course_id).and_return(invalid_course_id)
        allow(focus).to receive(:default_focus).and_return(course)
      end

      it 'sets the focus to the first course' do
        expect(focus.course).to eq(course)
      end
    end

    context 'with an invalid section in focus,' do
      # Create a stubbed object to guarantee that we get a section id
      # that's not in use by a real section. Using a hardcoded number for
      # the id can make this test fail if @section from the before block
      # is created with the supposedly "invalid" id.
      let(:invalid_section_id) { build_stubbed(:section).id }
      let(:course) { build_stubbed(:course) }
      let(:focus) do
        Focus.new(
          valid_user,
          valid_program,
          valid_program_id => {
            'course_id' => course.id, 'section_id' => invalid_section_id
          }
        )
      end

      before do
        allow(focus).to receive(:course_id).and_return(nil)
        allow(focus).to receive(:section_id).and_return(invalid_section_id)
        allow(focus).to receive(:default_focus).and_return(course)
      end

      it 'sets the focus to the first course' do
        expect(focus.course).to eq(course)
      end
    end

    context 'with nothing in focus' do
      context 'when the user is a instructor for a section but not a course owner' do
        it 'returns the course their section belongs to' do
          @section.instructors << valid_user
          focus = Focus.new(
            valid_user,
            valid_program,
            valid_program_id => {
              'course_id' => nil,
              'section_id' => nil
            }
          )
          expect(focus.course).to eq(@course)
        end
      end

      context 'when the user has no courses or sections' do
        it 'returns nil' do
          focus = Focus.new(
            valid_user,
            valid_program,
            valid_program_id => {
              'course_id' => nil,
              'section_id' => nil
            }
          )
          expect(focus.course).to be_nil
        end
      end
    end
  end

  describe '#same_school_as_course?' do
    let(:school_2) { build_stubbed(:school) }
    let(:course) { create(:closed_course, school: build_stubbed(:school)) }
    let(:focus) do
      Focus.new(
        valid_user,
        valid_program,
        valid_program_id => { 'course_id' => course.id }
      )
    end

    it 'returns true when the course is in the specified school' do
      expect(focus.same_school_as_course?(course.school)).to be_truthy
    end

    it 'returns false when the course is not in the specified school' do
      expect(focus.same_school_as_course?(school_2)).to be_falsey
    end

    it 'returns false when no school is specified' do
      expect(focus.same_school_as_course?(nil)).to be_falsey
    end

    it 'returns false when course is nil' do
      expect(focus).to receive(:course).and_return(nil)
      expect(focus.same_school_as_course?(course.school)).to be_falsey
    end
  end

  context "when focus is blank," do
    before do
      @course_1 = create(:course, name: 'Course 1', owner_id: valid_user.id,
                                           program: valid_program, school: build_stubbed(:school))
      @section_1  = create(:section, name: 'Section 1', course_id: @course_1.id,
                                              instructor_id: valid_user.id)
      @focus = Focus.new(valid_user, valid_program, valid_focus_params)
    end

    it 'sets the focus to the first course if no focus is given' do
      expect(@focus.course).to eq(@course_1)
    end

    it 'returns all sections for the first course' do
      expect(@focus.sections).to eq([@section_1])
    end
  end

  context 'when focus is a course' do
    let(:course_1) do
      create(
        :course,
        name: 'Course 1',
        owner_id: valid_user.id,
        program: valid_program,
        school: build_stubbed(:school)
      )
    end
    let(:focus) do
      Focus.new(
        valid_user,
        valid_program,
        valid_program_id => { 'course_id' => course_1.id}
      )
    end

    before(:each) do
      @section_1 = create(:section, name: 'Section 1', course_id: course_1.id, instructor: valid_user)
      @course_2  = create(:course, name: 'Course 2', owner_id: valid_user.id,
                                    program: valid_program, school: build_stubbed(:school))
      @section_2 = create(:section, name: 'Section 2', course_id: @course_2.id, instructor: valid_user)
    end

    context "always," do
      it "returns one course" do
        expect(focus.course).to eq(course_1)
      end

      it "returns all sections in the course focus" do
        expect(focus.sections).to eq([@section_1])
      end

      it "returns course and the course id for #type_and_id" do
        expect(focus.type_and_id).to eq("Course,#{course_1.id}")
      end

      it "returns 'course' for #type" do
        expect(focus.type).to eq('course')
      end
    end

    context "when the session course value is invalid" do
      before(:each) do
        allow(Course).to receive(:find).with(course_1.id).and_raise(ActiveRecord::RecordNotFound)
        allow(focus).to receive(:default_focus).and_return(@course_2)
      end

      it "changes the focus to a valid course" do
        expect(focus.course).to eq(@course_2)
      end
    end

    it "returns all students in the course focus from the student sorter" do
      students = [ double(Student) ]
      expect(student_sorter).to receive(:students).and_return(students)
      expect(focus.students).to eql students
    end
  end

  context "when focus is a section" do
    before(:each) do
      @course_2  = create(:course, name: 'Course 2', owner_id: valid_user.id,
                                           program: valid_program, school: build_stubbed(:school))
      @section_2_2 = create(:section, name: 'Section 2-2', course_id: @course_2.id,
                                              instructor_id: valid_user.id)
    end

    context "always," do
      before(:each) do
        @focus = Focus.new(valid_user, valid_program, valid_program_id => {'section_id' => @section_2_2.id})
      end

      it "returns the course for the section focus" do
        expect(@focus.course).to eq(@course_2)
      end

      it "returns one sections" do
        expect(@focus.sections).to eq([@section_2_2])
      end

      it "returns course and the course id for #type_and_id" do
        expect(@focus.type_and_id).to eq("Section,#{@section_2_2.id}")
      end

      it "returns 'section' for #type" do
        expect(@focus.type).to eq('section')
      end
    end

    context "when the session section value is invalid" do
      before(:each) do
        @focus = Focus.new(valid_user, valid_program, valid_program_id => {'section_id' => @section_2_2.id+1})
      end

      it "changes the focus to a valid course" do
        expect(@focus.course).to eq(@course_2)
      end
    end

    it "returns all students in the section focus" do
      users_2_2 = [ create(:student, username: 'user5', email: 'user5@vistahigherlearning.com'),
                    create(:student, username: 'user6', email: 'user6@vistahigherlearning.com') ]
      users_2_2.each {|user| Enrollment.create(user: user, section: @section_2_2)}
      focus = Focus.new(valid_user, valid_program, valid_program_id => {'section_id' => @section_2_2.id})
      students = [double(Student)]
      expect(student_sorter).to receive(:students).and_return(students)
      expect(focus.students).to eql students
    end

  end

  describe "#class_days" do
    context "when focused on a section" do
      before(:each) do
        @course = create(:course)
        @course.sections << create(:section, class_days: '1,2,3')
        @focus = Focus.new(valid_user, valid_program, valid_program_id => {'section_id' => @course.sections.first.id})
      end

      context "always" do
        it "returns an array of numbers" do
          allow(@course).to receive(:section_class_days_vary?).and_return(false)
          expect(@focus.class_days).to eq(['1','2','3'])
        end
      end

      context "and the section's course has another section with differing class days" do
        before(:each) do
          @course.sections << create(:section, class_days: '2,3,4')
          allow(@course).to receive(:section_class_days_vary?).and_return(true)
        end

        it "returns the class days of the focused section" do
          expect(@focus.class_days).to eq(['1','2','3'])
        end
      end
    end

    context "when focused on a course" do
      before(:each) do
        @course = create(:course)
        section = create(:section, course: @course, class_days: '1,2,3', instructor: valid_user)
        @focus = Focus.new(
          valid_user,
          valid_program,
          valid_program_id => {'course_id' => @course.id}
        )
      end

      context "when class days are the same for all sections" do
        before(:each) do
          section = create(:section, course: @course, class_days: '1,2,3', instructor: valid_user)
          allow(@course).to receive(:section_class_days_vary?).and_return(true)
        end

        it "returns the expected class days" do
          expect(@focus.class_days).to eq(['1','2','3'])
        end
      end

      context "when the class days are different across sections" do
        before(:each) do
          section = create(:section, course: @course, class_days: '2,3', instructor: valid_user)
          allow(@course).to receive(:section_class_days_vary?).and_return(true)
        end

        it "returns an empty array" do
          expect(@focus.class_days).to eq([])
        end
      end
    end
  end

  context "when focus has course and section" do

    before(:each) do
      @course_2  = create(:course, name: 'Course 2', owner_id: valid_user.id,
                                           program: valid_program, school: build_stubbed(:school))
      @section_2_1 = create(:section, name: 'Section 2-1', course_id: @course_2.id,
                                              instructor_id: valid_user.id)
    end

    before(:each) do
      @focus = Focus.new(valid_user, valid_program, valid_program_id => {'course_id' => @course_2.id, 'section_id' => @section_2_1.id})
    end

    it "returns the course associated with the section" do
      expect(@focus.course).to eq(@course_2)
    end

    it "returns 'section' for #type" do
      expect(@focus.type).to eq('section')
    end

    it "returns all students in the section focus" do
      users_2_1 =[ create(:student, username: 'user3', email: 'user3@vistahigherlearning.com'),
                     create(:student, username: 'user4', email: 'user4@vistahigherlearning.com') ]
      users_2_1.each {|user| Enrollment.create(user: user, section: @section_2_1)}
      focus = Focus.new(valid_user, valid_program, valid_program_id => {'course_id' => @course_2.id, 'section_id' => @section_2_1.id})
      students = [double(Student)]
      expect(student_sorter).to receive(:students).and_return(students)
      expect(focus.students).to eql students
    end
  end

  describe "#has_atleast_one_actionable_section?" do
    it "returns false when there is no course " do
      allow(valid_user).to receive(:student?).and_return(false)
      focus = Focus.new(valid_user, valid_program, valid_focus_params)
      allow(focus).to receive(:course).and_return(nil)
      expect(focus.has_atleast_one_actionable_section?).to be_falsey
    end

    it "returns false when there is are no sections" do
      allow(valid_user).to receive(:student?).and_return(false)
      @focus = Focus.new(valid_user, valid_program, valid_focus_params)
      @course = build_stubbed(:course)
      allow(@focus).to receive(:course).and_return(@course)
      allow(@focus).to receive(:sections).and_return([])
      expect(@focus.has_atleast_one_actionable_section?).to be_falsey
    end

  end

  describe "#focused_on_only_one_section?" do

    context "without course" do
      let(:focus_without_course) { Focus.new(valid_user, valid_program, valid_focus_params) }

      before(:each) do
       allow(valid_user).to receive(:student?).and_return(false)
       allow(focus_without_course).to receive(:course).and_return(nil)
      end

      it "returns false" do
       expect(focus_without_course).not_to be_focused_on_only_one_section
      end
    end

    context "with course" do
      let(:focus_with_course) { Focus.new(valid_user, valid_program, valid_focus_params) }

      before(:each) do
       allow(valid_user).to receive(:student?).and_return(false)
       allow(focus_with_course).to receive(:course).and_return( build_stubbed(:course) )
      end

      it "returns false when focus is set to a course and that course has multiple sections" do
        allow(focus_with_course).to receive(:sections).and_return( [build_stubbed(:section), build_stubbed(:section)] )
        expect(focus_with_course).not_to be_focused_on_only_one_section
      end

      it "returns true when focus is set to a single section" do
        allow(focus_with_course).to receive(:sections).and_return( [build_stubbed(:section)] )
        expect(focus_with_course).to be_focused_on_only_one_section
      end

      it "returns true when focus is set to a course and that course has only one section" do
        course = build_stubbed(:course, owner: valid_user)
        section = create(:section, course: course, instructor: valid_user)
        allow(focus_with_course).to receive(:course).and_return( course )
        expect(focus_with_course).to be_focused_on_only_one_section
      end
    end
  end

  describe '#students_in_all_sections' do
    let(:student) { double(Student) }
    let(:course) { double(Course, id: '1') }
    let(:section) { double(Section, id: '1', students: [student], course: course) }

    context 'given a course' do
      it 'returns all students in all sections that instructor can access' do
        focus = Focus.new(valid_user, valid_program, { valid_program_id => { 'course_id' => course.id }})
        allow(Course).to receive(:find).and_return(course)
        expect(course).to receive(:sections_by_instructor).and_return([section])
        expect(focus.students_in_all_sections).to eq([student])
      end
    end

    context 'given a section' do
      it 'returns all students in all sections that instructor can access' do
        focus = Focus.new(valid_user, valid_program, { valid_program_id => { 'section_id' => section.id }})
        allow(focus).to receive(:default_focus).and_return(course)
        allow(Section).to receive(:find).and_return(section)
        allow(Section).to receive(:find_by_id).and_return(section)
        expect(course).to receive(:sections_by_instructor).and_return([section])
        expect(focus.students_in_all_sections).to eq([student])
      end
    end
  end

  describe '#allow_instructor_to_view_student?' do
    let(:focus) { Focus.new(valid_user, valid_program, valid_focus_params) }
    let(:student) { double(Student) }

    context 'when the student is in a section the instructor can access' do
      it 'returns true' do
        allow(focus).to receive(:students_in_all_sections).and_return([student])
        expect(focus).to be_allowed_to_view_student(student)
      end
    end

    context 'when the student is in a section the instructor cannot access' do
      it 'returns false' do
        allow(focus).to receive(:students_in_all_sections).and_return([])
        expect(focus).not_to be_allowed_to_view_student([student])
      end
    end
  end

  describe "#course_and_section_params" do
    context "without course" do
      let(:focus_without_course) { Focus.new(valid_user, valid_program, valid_focus_params) }

      before(:each) do
       allow(valid_user).to receive(:student?).and_return(false)
       allow(focus_without_course).to receive(:course).and_return(nil)
      end

      it "returns the course param as nil" do
        expect(focus_without_course.course_and_section_params).to eq({course: nil})
      end
    end

    context "with course" do
      let(:focus_with_course) { Focus.new(valid_user, valid_program, valid_focus_params) }
      let(:course) { build_stubbed(:course) }
      let(:section) { build_stubbed(:section) }

      before(:each) do
       allow(valid_user).to receive(:student?).and_return(false)
       allow(focus_with_course).to receive(:course).and_return(course)
      end

      it "returns the course param only if not focused on a section" do
        allow(focus_with_course).to receive(:sections).and_return( [build_stubbed(:section), build_stubbed(:section)] )
        expect(focus_with_course.course_and_section_params).to eq({course: course})
      end

      it "returns the course and section params focused on a section" do
        allow(focus_with_course).to receive(:sections).and_return( [section] )
        expect(focus_with_course.course_and_section_params).to eq({course: course, section: section})
      end
    end
  end

  describe '#sections' do
    context 'when the instructor has no courses or sections' do
      it 'returns an empty array' do
        focus = Focus.new(valid_user, valid_program, {})
        expect(focus.sections).to be_empty
      end
    end

    context 'when the instructor has a course but no sections' do
      it 'returns an empty array' do
        course = create(:course, owner: valid_user)
        focus = Focus.new(valid_user, valid_program, valid_program_id => { 'course_id' => course.id })
        expect(focus.sections).to be_empty
      end
    end

    context "when there is an invalid course" do
      it 'returns an empty array' do
        focus = Focus.new(valid_user, valid_program, valid_program_id => { 'course_id' => 123 })
        expect(focus.sections).to be_empty
      end
    end

    context "when there is an invalid section" do
      it 'returns an empty array' do
        focus = Focus.new(valid_user, valid_program, valid_program_id => { 'section_id' => 123 })
        expect(focus.sections).to be_empty
      end
    end

    context 'given a course with a section that the instructor is teaching' do
      it 'returns only the sections that belong to the user' do
        course = create(:course)
        section_1 = create(:section, course: course, instructor: valid_user)
        section_2 = create(:section, course: course) # other instructor

        focus = Focus.new(valid_user, valid_program, valid_program_id => { 'course_id' => course.id })
        expect(focus.sections).to eq([section_1])
      end
    end

    context 'given a section' do
      it 'returns the given section' do
        section_1 = create(:section)
        focus = Focus.new(valid_user, valid_program, valid_program_id => { 'section_id' => section_1.id })
        expect(focus.sections).to eq([section_1])
      end
    end

    context 'given a course and a section' do
      it 'returns the given section' do
        course = create(:course)
        section_1 = create(:section, course: course)
        section_2 = create(:section, course: course)
        focus = Focus.new(valid_user, valid_program, valid_program_id => { 'section_id' => section_1.id })
        expect(focus.sections).to eq([section_1])
      end
    end
  end

  describe '#all_sections_in_course' do
    context 'when a course is in focus' do
      before do
        @course = create(:open_course, name: 'focused', owner: valid_user)
        section = create(:section, course: @course)
        section.instructors << valid_user

        @focus = Focus.new(valid_user, valid_program, valid_program_id => {'course_id' => @course.id} )
      end

      it 'returns all of its sections' do
        expect(@focus.sections).to match(@course.sections)
      end
    end

    context 'when a section is in focus' do
      before do
        @course = create(:open_course, owner: valid_user)
        section = create(:section, name: 'not focused', course: @course)
        section.instructors << valid_user

        focused_section = create(:section, name: 'focused', course: @course)
        focused_section.instructors << valid_user

        @focus = Focus.new(valid_user, valid_program, valid_program_id => {'course_id' => @course.id, 'section_id' => focused_section.id} )
      end

      it "returns all of its course's sections" do
        expect(@focus.all_sections_in_course).to match(@course.sections)
      end
    end
  end

  describe '#focused_on_course?' do
    before(:each) do
      @instructor = create(:instructor)
      @course = create(:open_course, name: 'focused', owner: @instructor)
      @section_1 = create(:section, course: @course, instructor: @instructor)
      @section_2 = create(:section, course: @course, instructor: @instructor)
    end

    let(:focus) { Focus.new(@instructor, valid_program,
                          valid_program_id => {'section_id' => @section_1.id} ) }

    it 'returns false if course does not exist' do
      allow(focus).to receive(:course).and_return(nil)
      expect(focus).not_to be_focused_on_course
    end

    it "returns false when not focused on course" do
      expect(focus).not_to be_focused_on_course
    end

    it "returns true when focused on course" do
      focus = Focus.new(@instructor, valid_program,
                        valid_program_id => {'course_id' => @course.id} )
      expect(focus).to be_focused_on_course
    end
  end

  describe '#focused_on_section?' do
    before(:each) do
      @instructor = create(:instructor)
      @course = create(:open_course, name: 'focused', owner: @instructor)
      @section_1 = create(:section, course: @course, instructor: @instructor)
      @section_2 = create(:section, course: @course, instructor: @instructor)
    end

    let(:focus) { Focus.new(@instructor, valid_program,
                          valid_program_id => {'course_id' => @course.id} ) }

    it 'returns false if there are no sections' do
      allow(focus).to receive(:sections).and_return(nil)
      expect(focus).not_to be_focused_on_section
    end

    it "returns false when not focused on a section" do
      expect(focus).not_to be_focused_on_section
    end

    it "returns true when focused on section" do
      focus = Focus.new(@instructor, valid_program,
                        valid_program_id => {'section_id' => @section_1.id} )
      expect(focus).to be_focused_on_section
    end
  end

  describe '#focused?' do
    let(:focus) { described_class.new(valid_user, valid_program, valid_focus_params) }

    context 'when focus is blank' do
      it "returns false" do
        expect(focus.focused?).to be_falsey
      end
    end

    context 'when focus is on a course' do
      let(:course) { create(:course) }
      let(:valid_focus_params) do
        {
          valid_program_id => { "course_id" => course.id }
        }
      end

      it "returns true" do
        expect(focus.focused?).to be_truthy
      end
    end

    context 'when focus is on a section' do
      let(:course) { create(:course_with_sections) }
      let(:section) { course.sections.first }
      let(:valid_focus_params) do
        {
          valid_program_id => { "section_id" =>  section.id }
        }
      end

      it "returns true" do
        expect(focus.focused?).to be_truthy
      end
    end
  end

  def verify_student_list(focus, expected)
    students = focus.students
    expect(students.count).to eq(expected.count)
    students.all?{|student| expected.include?(student) }
  end
end

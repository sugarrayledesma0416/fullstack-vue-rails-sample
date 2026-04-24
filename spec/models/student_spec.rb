describe Student do
  describe "#sufficient_access_for_course?" do
    let(:student) { create(:student) }
    let(:section) { create(:section) }

    context "enrollment with sufficient access exists" do
      it "returns true" do
        enrollment_with_access = create(:enrollment, :user => student,
                                         :section => section, :state => 'enrolled',
                                         :sufficient_access => true)
        expect(student.sufficient_access_for_course?(section)).to be_truthy
      end
    end

    context "enrollment with sufficient access does not exist" do
      it "returns false" do
        enrollment_with_access = create(:enrollment, :user => student,
                                         :section => section, :state => 'enrolled',
                                         :sufficient_access => false)
        expect(student.sufficient_access_for_course?(section)).to be_falsey
      end
    end
  end

  describe "#old_viewable_section?" do
    let(:student) { build_stubbed(:student) }
    let(:section) { build_stubbed(:section) }

    it "returns false if section is archived" do
      allow(section).to receive(:archived?).and_return(true)
      expect(student).not_to be_old_viewable_section(section)
    end

    it "returns false if section is not closed" do
      allow(section).to receive(:archived?).and_return(false)
      allow(section).to receive(:closed?).and_return(false)
      expect(student).not_to be_old_viewable_section(section)
    end

    it "returns false if user was never a student of given section" do
      allow(section).to receive(:archived?).and_return(false)
      allow(section).to receive(:closed?).and_return(true)
      allow(student).to receive(:enrolled_in?).and_return(false)
      expect(student).not_to be_old_viewable_section(section)
    end

    context "section not archived" do
      context "section closed" do
        context "user was a student of the give section" do
          it "returns true" do
            allow(section).to receive(:archived?).and_return(false)
            allow(section).to receive(:closed?).and_return(true)
            allow(student).to receive(:enrolled_in?).and_return(true)
            expect(student).to be_old_viewable_section(section)
          end
        end
      end
    end
  end

  describe "#has_access_to_section_in_program?" do
    def mock_session(program, section_id)
      { most_recent_section: { "program_#{program.id}" => section_id } }
    end

    let(:student) { create(:student) }
    let(:section) { build_stubbed(:section) }
    let(:other_section) { build_stubbed(:section) }
    let(:program) { build_stubbed(:program) }

    it "return true if the section is section_zero" do
      allow(section).to receive(:section_zero?).and_return(true)
      expect(student).to have_access_to_section_in_program(
        section,
        program,
        mock_session(program, section.id)
      )
    end

    it "return true if the section is an old viewable section" do
      allow(section).to receive(:section_zero?).and_return(false)
      allow(student).to receive(:old_viewable_section?).and_return(true)
      expect(student).to have_access_to_section_in_program(
        section,
        program,
        mock_session(program, section.id)
      )
    end

    it "return true if the given section is same as the current section in the given program" do
      allow(section).to receive(:section_zero?).and_return(false)
      allow(student).to receive(:old_viewable_section?).and_return(false)
      allow(student).to receive(:current_section_in_program).and_return(section)
      expect(student).to have_access_to_section_in_program(
        section,
        program,
        mock_session(program, section.id)
      )
    end

    it "return false if the given section is not same as the current section in the given program" do
      allow(section).to receive(:section_zero?).and_return(false)
      allow(student).to receive(:old_viewable_section?).and_return(false)
      allow(student).to receive(:current_section_in_program).and_return(other_section)
      expect(student).not_to have_access_to_section_in_program(
        section,
        program,
        mock_session(program, section.id)
      )
    end
  end

  describe "#enrolled_in?"do
    let(:program) { create(:program)}
    let(:student) { create(:student)}
    let(:course)  { create(:course, :program => program)}
    let(:section_1)  { create(:section, :course => course)}
    let(:section_2)  { create(:section, :course => course)}

    it "return false when there are no enrollments for the give section " do
       enrollment = create(:enrollment, :user => student, :section => section_2)
       expect(student).not_to be_enrolled_in(section_1)
    end

    it "return false when enrollment is neither marked completed or enrolled" do
       enrollment = create(:enrollment, :user => student, :section => section_1, :state => 'transferred')
       expect(student).not_to be_enrolled_in(section_1)
    end

    it "return true when enrollment is marked completed" do
       enrollment = create(:enrollment, :user => student, :section => section_1, :state => 'marked_complete')
       expect(student).to be_enrolled_in(section_1)
    end

    it "return true when enrollment is active" do
       enrollment = create(:enrollment, :user => student, :section => section_1)
       expect(student).to be_enrolled_in(section_1)
    end
  end

  describe "#most_relevant_section" do
    it "should return relevant section" do
       program = create(:program)
       student = create(:student)

       course_1 = create(:course, :program => program)
       section_1_1 = create(:section, :course => course_1)

       course_2 = create(:course, :program => program)
       section_2_1 = create(:section, :course => course_2)
       section_2_2 = create(:section, :course => course_2)

       enrollment = create(:enrollment, :user => student, :section => section_2_1)

       allow(student).to receive(:active_or_completed_enrollments_in_editable_course_by_section).and_return([enrollment])

       expect(student.most_relevant_section([section_1_1, section_2_1, section_2_2])).to eql section_2_1
    end

    context "when the student is in multiple sections in the program" do
      # TODO: update this example when we add full support for CE
      it "does not raise an error" do
        program = create(:program)
        student = create(:student)

        course_1 = create(:course, :program => program)
        section_1_1 = create(:section, :course => course_1)

        course_2 = create(:course, :program => program)
        section_2_1 = create(:section, :course => course_2)
        section_2_2 = create(:section, :course => course_2)

        enrollment_1 = create(:enrollment, :user => student, :section => section_2_1)
        enrollment_2 = create(:enrollment, :user => student, :section => section_2_2)
        allow(student).to receive(
          :active_or_completed_enrollments_in_editable_course_by_section
        ).and_return([enrollment_1, enrollment_2])

        expect {
          student.most_relevant_section([section_1_1, section_2_1, section_2_2])
        }.not_to raise_error ConcurrentSectionsError
      end
    end

    context "when the student is in a section from a non editable course" do
      it "returns nil" do
       program = create(:program)
       student = create(:student)

       course_1 = create(:closed_course, program:)
       section_1_1 = create(:section, course: course_1)

       course_2 = create(:course, program:)
       section_2_1 = create(:section, course: course_2)
       section_2_2 = create(:section, course: course_2)

       enrollment_1 = create(:enrollment, user: student, section: section_2_1)
       allow(student).to receive(:active_or_completed_enrollments_in_editable_course_by_section).and_return([])

       expect(student.most_relevant_section([section_1_1, section_2_1, section_2_2])).to be_nil
      end
    end

  end

  describe "#active_sections" do
    let(:student) { create(:student) }
    let(:program) { create(:program) }

    it "returns the sections associated with any active enrollments" do
      section_1 = create(:section, :course => create(:course, :program => program))
      section_2 = create(:section, :course => create(:course, :program => program))

      Enrollment.create!(:user => student, :section => section_1)
      Enrollment.create!(:user => student, :section => section_2)

      expect(student.active_sections).to eql([section_1, section_2])
    end

    it "returns sections with only active enrollments" do
      section_1 = create(:section, :course => create(:course, :program => program))
      section_2 = create(:section, :course => create(:course, :program => program))

      Enrollment.create!(:user => student, :section => section_1, :state => 'marked_complete')
      Enrollment.create!(:user => student, :section => section_2, :state => 'enrolled')

      expect(student.active_sections).to eql([section_2])
    end
  end

  describe "#enrolled_in_sections" do
    let(:student_1) { create(:student) }
    let(:student_2) { create(:student) }
    let(:student_3) { create(:student) }
    let(:student_4) { create(:student) }
    let(:section_1) { build_stubbed(:section) }
    let(:section_2) { build_stubbed(:section) }
    let!(:enrollment_1) { create(:enrollment, :user => student_1, :section => section_1, :state => 'enrolled') }
    let!(:enrollment_2) { create(:enrollment, :user => student_2, :section => section_1, :state => 'marked_complete') }
    let!(:enrollment_3) { create(:enrollment, :user => student_3, :section => section_2, :state => 'enrolled') }
    let!(:enrollment_4) { create(:enrollment, :user => student_4, :section => section_2, :state => 'dropped') }

    it "returns students for one section" do
      expect(Student.enrolled_in_sections(section_1).to_a).to eql [student_1, student_2]
    end

    it "returns students for multiple sections" do
      expect(Student.enrolled_in_sections([section_1, section_2]).to_a).to eql [student_1, student_2, student_3]
    end

    it "does not return dropped students" do
      expect(Student.enrolled_in_sections(section_2).to_a).to eql [student_3]
      expect(Student.enrolled_in_sections(section_2)).not_to include student_4
    end

    context "when a student transfers to another section in the same course" do
      let!(:enrollment_5) { create(:enrollment, :user => student_4, :section => section_1, :state => 'enrolled') }

      it "returns the associated enrolled reference" do
        results = Student.enrolled_in_sections([section_1, section_2])
        st4 = results.select { |st| st.id == student_4.id }
        expect(st4.size).to eq(1)
        expect(st4.first.enrollments.size).to eq(1)
        expect(st4.first.enrollments.first.state).to eq('enrolled')
      end
    end

  end

  describe ".accessible_program?" do
    let(:user) { build_stubbed(:student) }
    let(:program) { build_stubbed(:program) }

    it "returns false if user has no programs" do
      allow(user).to receive(:programs).and_return([])
      expect(user.accessible_program?(program)).to be_falsey
    end

    it "returns false when the given program is not among the user programs" do
      other_program = build_stubbed(:program)
      allow(user).to receive(:programs).and_return([other_program])
      expect(user.accessible_program?(program)).to be_falsey
    end

    it "returns false when the given program is among the user programs" do
      other_program = build_stubbed(:program)
      allow(user).to receive(:programs).and_return([other_program, program])
      expect(user.accessible_program?(program)).to be_truthy
    end
  end

  describe "#active_section?" do
    let(:user) { build_stubbed(:student) }
    let(:section) { build_stubbed(:section) }

    it "returns false if there are no active sections" do
      allow(user).to receive(:active_sections).and_return([])
      expect(user.active_section?(section)).to be_falsey
    end

    it "returns false when the given section is not among the active sections" do
      other_section = build_stubbed(:section)
      allow(user).to receive(:active_sections).and_return([other_section])
      expect(user.active_section?(section)).to be_falsey
    end

    it "returns true when the given section is among the active sections" do
      other_section = build_stubbed(:section)
      allow(user).to receive(:active_sections).and_return([other_section, section])
      expect(user.active_section?(section)).to be_truthy
    end
  end

  describe "pubnub_client_roster" do
    let(:student) { create(:student) }
    let(:course) { create(:course) }
    let(:section) { create(:section, course: course) }

    before do
      create(:active_enrollment, section: section, user: student)
    end

    it "produces a hash with basic user info" do
      expect(student.pubnub_client_roster[:user])
        .to eq({uuid: student.id.to_s,
                name: student.username,
                first_name: student.first_name,
                last_name: student.last_name})
    end

    it "returns an array of courses, each with an array of sections" do
      expect(student.pubnub_client_roster[:roster])
        .to eq(groups: [
                        {
                         id: "course_#{course.id}",
                         name: course.name,
                         program_id: course.program_id,
                         chat_level: course.chat_level,
                         sections: [
                                     {
                                      id: "section_#{section.id}",
                                      name: section.name,
                                      users: [{
                                        uuid: section.instructor.id.to_s,
                                        first_name: section.instructor.first_name,
                                        last_name: section.instructor.last_name
                                      }]
                                     }
                                   ]
                        }
                       ]
              )
    end

    it 'contains an array of students and instructors associated to a section' do
      enrollment = create(:active_enrollment, section: section)
      teammate = enrollment.user
      section.reload

      expect(student.pubnub_client_roster[:roster])
        .to eq(groups: [
                        {
                         id: "course_#{course.id}",
                         name: course.name,
                         program_id: course.program_id,
                         chat_level: course.chat_level,
                         sections: [
                                     {
                                      id: "section_#{section.id}",
                                      name: section.name,
                                      users: [{
                                        uuid: teammate.id.to_s,
                                        first_name: teammate.first_name,
                                        last_name: teammate.last_name
                                      }, {
                                        uuid: section.instructor.id.to_s,
                                        first_name: section.instructor.first_name,
                                        last_name: section.instructor.last_name
                                      }]
                                     }
                                   ]
                        }
                       ]
              )
    end
  end

  describe "#current_section_in_program" do
    let(:student) { create(:student) }

    context 'when the student is in no sections in the program' do
      it 'returns nil' do
        this_program = create(:program)
        expect(student.current_section_in_program(this_program)).to be_nil
      end
    end

    context 'when the student is enrolled in one section in the program' do
      it 'returns that section' do
        this_program = create(:program)
        other_program = create(:program)

        this_course = create(:course, program: this_program)
        this_section = create(:section, course: this_course)

        other_course = create(:course, program: other_program)
        other_section = create(:section, course: other_course)

        student.sections << this_section
        student.sections << other_section
        expect(student.current_section_in_program(this_program)).to eq(this_section)
      end
    end

    context 'when the student is in multiple sections in the program' do
      let(:program) { create(:program) }
      let(:course_1) { create(:course, program:) }
      let(:course_2) { create(:course, program:) }
      let(:section_1) { create(:section, course: course_1) }
      let(:section_2) { create(:section, course: course_2) }

      before do
        student.sections << section_1
        student.sections << section_2
      end

      it 'returns the first section if no session is specified' do
        expect(student.current_section_in_program(program)).to eq(section_1)
      end

      it 'returns the first section if a session with no ' \
         'most_recent_section key is specified' do
        expect(student.current_section_in_program(program, {})).to eq(section_1)
      end

      context 'when a session with most_recent_section key is specified' do
        def mock_session(program, section_id)
          { most_recent_section: { "program_#{program.id}" => section_id } }
        end

        it 'returns the first section if there is no most_recent_section ' \
           'entry matching the specified program id' do
          other_program = create(:program)
          expect(
            student.current_section_in_program(
              program, mock_session(other_program, section_1.id)
            )
          ).to eq(section_1)
        end

        it "returns the first section if the none of the student's " \
           'sections match the id of the most_recent_section entry for ' \
           'the specified program id' do
          expect(
            student.current_section_in_program(
              program, mock_session(program, section_2.id + 1)
            )
          ).to eq(section_1)
        end

        it 'returns the section with the id of the most_recent_section entry' \
           'for the specified program id if the student is enrolled in it' do
          expect(
            student.current_section_in_program(
              program, mock_session(program, section_2.id)
            )
          ).to eq(section_2)
        end
      end
    end
  end

  describe "#enrolled_in_section?" do
    it "" do
    end
  end

  describe '#has_attempts_in_section?' do
    let(:student) { create(:student) }
    let(:section) { create(:section) }

    it 'is true if user has any attempts in the specified section' do
      create(:attempt, section: section, user: student)
      expect(student).to have_attempts_in_section(section)
    end

    it 'is false if user has no attempts in the specified section' do
      create(:attempt, section: create(:section), user: student)
      expect(student).not_to have_attempts_in_section(section)
    end
  end

  describe "#spotcheck_count" do
    it "should return zero if my section is set" do
       student = create(:student)
       expect(student.spotcheck_count).to be_zero
    end

    it "should look up student spotcheck counts table " do
       student = create(:student)
       student.my_current_section = create(:section)
       allow(student).to receive(:student_spotcheck_counts).and_return([])
       expect(student).to receive(:student_spotcheck_counts).and_return([])
       expect(student.spotcheck_count).to be_zero
    end

    it "should return zero if no spotcheck count found" do
       student = create(:student)
       section = create(:section)
       student.my_current_section = section
       student_spotcheck_count = create(:student_spotcheck_count,:user => student, :section => section)

       expect(student.spotcheck_count).to equal(student_spotcheck_count.count)
    end

  end

  describe "#hashed_attempts" do
    let (:student) { create(:student) }
    let (:section) { create(:section) }
    let (:activity_1) { create(:activity) }
    let (:activity_2) { create(:activity) }

    it 'returns a hash of arrays of attempts, grouped by the hash_key method for each attempt' do
      activity_1_attempt = create(:attempt, :user => student, :section => section, :activity => activity_1)
      activity_2_attempt = create(:attempt, :user => student, :section => section, :activity => activity_2)
      result = student.hashed_attempts
      expect(result[activity_1_attempt.hash_key]).to eql [activity_1_attempt]
      expect(result[activity_2_attempt.hash_key]).to eql [activity_2_attempt]
    end

    it 'sorts the array of attempts that share the same hash key by attempt number, descending' do
      attempt_1 = create(:attempt_submitted, :attempt_number => 1, :activity => activity_1,
                                                         :user => student, :section => section)
      attempt_2 = create(:attempt_completed, :attempt_number => 3, :activity => activity_1,
                                                         :user => student, :section => section)
      result = student.hashed_attempts
      expect(result[attempt_1.hash_key]).to eql [attempt_2, attempt_1]
    end
  end

  describe "#attempts_by_section" do
    let(:student) { create(:student)}
    let(:section) { create(:section) }
    let(:attempt_1) { create(:attempt, :user => student, :section => section) }
    let(:attempt_2) { create(:attempt, :user => student, :section => create(:section)) }

    it "returns attempts in the student's section" do
      expect(student.attempts_by_section(section)).to include(attempt_1)
    end

    it "excludes attempts not in the student's section" do
      expect(student.attempts_by_section(section)).not_to include(attempt_2)
    end
  end

  describe "#downloadable_resource" do
    let(:program) { create(:program) }
    let(:resource) { create(:resource, :program => program) }
    let(:student) { create(:student) }

    context "when a non zero section is specified" do
      it "finds the student viewable resource in the specified program with the specified id in the specified section" do
        section = create(:section)
        expect(program).to receive(:find_student_resource_for_section).with(resource.id, section).and_return(resource)
        expect(student.downloadable_resource(resource.id, program, section)).to eql resource
      end
    end

    context "when section zero is specified" do
      it "finds the student resource for that program with the specified id" do
        expect(program).to receive(:find_student_resource).with(resource.id).and_return(resource)
        expect(student.downloadable_resource(resource.id, program, Section.section_zero)).to eql resource
      end
    end

    context "when a nil section is specified" do
      it "finds the student resource for that program with the specified id" do
        expect(program).to receive(:find_student_resource).with(resource.id).and_return(resource)
        expect(student.downloadable_resource(resource.id, program, nil)).to eql resource
      end
    end
  end

  describe '#active_in_editable_section?' do
    it 'returns true if the student was enrolled in the section' do
      student = build_stubbed(:student)
      allow(student).to receive(:active_sections_in_editable_courses).and_return(['foo'])
      expect(student).to be_active_in_editable_section(['foo'])
    end

    it 'returns false if the student was not enrolled in the section' do
      student = build_stubbed(:student)
      allow(student).to receive(:active_sections_in_editable_courses).and_return(['foo'])
      expect(student).not_to be_active_in_editable_section(['bar'])
    end
  end

  describe '#pubnub_client_roster' do
    let(:student) { create(:student) }
    let(:instructor) { create(:instructor) }
    let(:instructor_info) do
      {
        first_name: instructor.first_name,
        last_name: instructor.last_name,
        uuid: instructor.id.to_s
      }
    end

    def section_info(section)
      {
        id: "section_#{section.id}",
        name: section.name,
        users: [instructor_info]
      }
    end

    it 'contains a :user key with a hash of basic user info' do
      expect(student.pubnub_client_roster[:user]).to eq(
        first_name: student.first_name,
        last_name: student.last_name,
        name: student.username,
        uuid: student.id.to_s
      )
    end

    it "contains a :roster key with a hash of the students's courses and sections" do
      course = create(:open_course)
      section = create(:section, course: course, instructor: instructor)
      create(:active_enrollment, section: section, user: student)

      result = student.pubnub_client_roster[:roster][:groups]

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

    it 'includes sections with courses that end today' do
      today = Time.zone.now.to_date
      course = create(:course, end_date: today)
      section = create(:section, course: course, instructor: instructor)
      create(:active_enrollment, section: section, user: student)

      result = student.pubnub_client_roster[:roster][:groups]

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

    it 'does not include sections in editable courses' do
      editable_course = create(:editable_course)
      section = create(:section, course: editable_course, instructor:)
      create(:active_enrollment, section:, user: student)

      result = student.pubnub_client_roster[:roster][:groups]

      expect(result).to eq([])
    end

    it 'includes sections in courses with chat disabled' do
      course = create(:course, chat_level: 'disabled')
      section = create(:section, course: course, instructor: instructor)
      create(:active_enrollment, section: section, user: student)

      result = student.pubnub_client_roster[:roster][:groups]

      expect(result).to match_array [
        {
          chat_level: 'disabled',
          id: "course_#{course.id}",
          name: course.name,
          program_id: course.program_id,
          sections: [section_info(section)]
        }
      ]
    end
  end

  describe '#pubnub_grants_roster' do
    let(:student) { create(:student) }

    it 'includes information about sections with active enrollments' do
      section = create(:section_with_course)
      create(:active_enrollment, section: section, user: student)

      result = student.pubnub_grants_roster[:roster][:groups]

      expect(result).to match_array [
        { id: "section_#{section.id}", name: section.name }
      ]
    end

    it 'does not include archived sections' do
      section = create(:section_with_course, archived: true)
      create(:active_enrollment, section: section, user: student)

      result = student.pubnub_grants_roster[:roster][:groups]

      expect(result).to eq([])
    end

    it 'includes sections with courses that end today' do
      today = Time.zone.now.to_date
      course_ending_today = create(:course, end_date: today)
      section = create(:section, course: course_ending_today)
      create(:active_enrollment, section: section, user: student)

      result = student.pubnub_grants_roster[:roster][:groups]

      expect(result).to match_array [
        { id: "section_#{section.id}", name: section.name }
      ]
    end

    it 'does not include sections in editable courses' do
      editable_course = create(:editable_course)
      section = create(:section, course: editable_course)

      create(:active_enrollment, section:, user: student)
      result = student.pubnub_grants_roster[:roster][:groups]

      expect(result).to eq([])
    end

    it 'does not include sections in courses with chat disabled' do
      disabled_course = create(:open_course, chat_level: 'disabled')
      section = create(:section, course: disabled_course)
      create(:active_enrollment, section: section, user: student)

      result = student.pubnub_grants_roster[:roster][:groups]

      expect(result).to eq([])
    end
  end
end
